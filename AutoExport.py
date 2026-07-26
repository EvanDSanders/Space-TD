import hashlib
import os
import shutil
import bpy

problems = []

def find_collections_with_prefix(prefix: str):
    return [c for c in bpy.data.collections if c.name.startswith(prefix)]

def collection_in_hierarchy(root, target):
    if root == target:
        return True
    return any(collection_in_hierarchy(child, target) for child in root.children)

def find_scene_for_collection(collection):
    for scene in bpy.data.scenes:
        if collection_in_hierarchy(scene.collection, collection):
            return scene
    return None

def collection_objects(collection):
    return list(collection.all_objects)

def find_origin_object(objects):
    for obj in objects:
        if obj.name.startswith("Origin."):
            return obj
    return None

def center_objects_at_world_origin(objects, origin):
    offset = origin.matrix_world.translation.copy()
    for obj in objects:
        obj.matrix_world.translation -= offset

def file_hash(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def find_export_target(objects_dir, export_name):
    target_name = f"{export_name}.glb".lower()
    for root, _dirs, files in os.walk(objects_dir):
        for fname in files:
            if fname.lower() == target_name:
                return os.path.join(root, fname)
    return os.path.join(objects_dir, f"{export_name}.glb")

def copy_if_changed(src, dst):
    if os.path.exists(dst) and file_hash(src) == file_hash(dst):
        print(f"Unchanged, skipping copy: {dst}")
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    print(f"Copied {src} -> {dst}")

def export_collection(collection, export_dir, scene):
    objects = collection_objects(collection)
    if not objects:
        print(f"Skipping empty collection: {collection.name}")
        problems.append(f"Skipping empty collection: {collection.name}")
        return

    origin = find_origin_object(objects)
    if origin is None:
        print(f"Skipping {collection.name}: no object starting with 'Origin.'")
        problems.append(f"Skipping {collection.name}: no object starting with 'Origin.'")

        return

    center_objects_at_world_origin(objects, origin)
    center_objects_at_world_origin(objects, origin)
    center_objects_at_world_origin(objects, origin)
    center_objects_at_world_origin(objects, origin)

    for obj in objects:
        obj.name = obj.name.replace(".", " ")

    # Apply all modifiers except ARMATURE and those with "IGN" in the name
    for obj in objects:
        for mod in list(obj.modifiers):
            if mod.type != 'ARMATURE' and "IGN" not in mod.name:
                bpy.context.view_layer.objects.active = obj
                bpy.ops.object.modifier_apply(modifier=mod.name)

    # Unhide (eye icon) so hidden objects still get selected and exported
    was_hidden = {obj: obj.hide_get() for obj in objects}
    for obj in objects:
        if was_hidden[obj]:
            obj.hide_set(False)

    try:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]

        export_name = collection.name.replace(".", " ")
        tmp_filepath = os.path.join("/tmp", f"{export_name}.glb")
        objects_dir = os.path.join(export_dir, "Objects")
        final_filepath = find_export_target(objects_dir, export_name)

        orig_scene_name = scene.name
        scene.name = export_name
        try:
            bpy.ops.export_scene.gltf(
                filepath=tmp_filepath,
                export_format="GLB",
                use_selection=True,
                export_apply=False,
                export_skins=True,
                export_all_influences=True,
                export_morph=False,
                export_animations=False,
                export_vertex_color='ACTIVE',
            )
        finally:
            scene.name = orig_scene_name
        print(f"Exported {tmp_filepath}")

        copy_if_changed(tmp_filepath, final_filepath)
    finally:
        for obj in objects:
            if was_hidden[obj]:
                obj.hide_set(True)

def main():
    export_dir = os.path.dirname(os.path.abspath(__file__))

    auto_export_collections = find_collections_with_prefix("Auto Export")
    if not auto_export_collections:
        raise RuntimeError("No collection starting with 'Auto Export' found")

    for auto_export in auto_export_collections:
        scene = find_scene_for_collection(auto_export)
        if scene is None:
            print(f"Skipping {auto_export.name}: not linked into any scene")
            problems.append(f"Skipping {auto_export.name}: not linked into any scene")
            continue

        bpy.context.window.scene = scene

        for collection in auto_export.children:
            export_collection(collection, export_dir, scene)

    for each in problems:
        print(each)

if __name__ == "__main__":
    main()
