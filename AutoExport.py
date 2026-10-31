import hashlib
import json
import os
import shutil
import struct
import subprocess
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
    object_set = set(objects)
    roots = [obj for obj in objects if obj.parent not in object_set]
    for obj in roots:
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

def glb_chunks(path):
    with open(path, "rb") as f:
        data = f.read()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        return None
    chunks = []
    offset = 12
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        chunk_data = data[offset + 8: offset + 8 + chunk_length]
        chunks.append((chunk_type, chunk_data))
        offset += 8 + chunk_length
    return chunks

def glb_json_chunk(path):
    chunks = glb_chunks(path)
    if not chunks:
        return None
    for chunk_type, chunk_data in chunks:
        if chunk_type == 0x4E4F534A:  # "JSON"
            return json.loads(chunk_data)
    return None

def print_chunk_hashes(src, dst):
    src_chunks = glb_chunks(src)
    dst_chunks = glb_chunks(dst)
    if not src_chunks or not dst_chunks:
        return
    names = {0x4E4F534A: "JSON", 0x004E4942: "BIN"}
    for i, ((s_type, s_data), (d_type, d_data)) in enumerate(zip(src_chunks, dst_chunks)):
        s_hash = hashlib.sha256(s_data).hexdigest()
        d_hash = hashlib.sha256(d_data).hexdigest()
        label = names.get(s_type, hex(s_type))
        status = "SAME" if s_hash == d_hash else "DIFFERS"
        print(f"  chunk[{i}] {label}: {status} (old {len(d_data)}B, new {len(s_data)}B)")

def write_pretty_json(path, obj):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2, sort_keys=True)
    return path

def print_diff(src, dst):
    print_chunk_hashes(src, dst)
    src_json = glb_json_chunk(src)
    dst_json = glb_json_chunk(dst)
    if src_json is not None and dst_json is not None:
        src_txt = write_pretty_json("/tmp/_diff_new.json", src_json)
        dst_txt = write_pretty_json("/tmp/_diff_old.json", dst_json)
        result = subprocess.run(
            ["diff", "--color=always", dst_txt, src_txt],
            capture_output=True,
            text=True,
        )
    else:
        result = subprocess.run(
            ["diff", "--color=always", dst, src],
            capture_output=True,
            text=True,
        )
    if result.stdout:
        print(result.stdout)
    elif result.stderr:
        print(result.stderr)

def copy_if_changed(src, dst):
    if os.path.exists(dst):
        if file_hash(src) == file_hash(dst):
            print(f"Unchanged, skipping copy: {dst}")
            return
        print_diff(src, dst)
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

    for obj in objects:
        obj.name = obj.name.replace(".", " ")

    # Convert curves to mesh (bakes modifiers); remove IGN modifiers first so they aren't baked
    for obj in objects:
        if obj.type == 'CURVE':
            for mod in list(obj.modifiers):
                if "IGN" in mod.name:
                    obj.modifiers.remove(mod)
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.convert(target='MESH')

    # Apply all modifiers except ARMATURE and those with "IGN" in the name
    for obj in objects:
        if obj.type == 'CURVE':
            continue
        for mod in list(obj.modifiers):
            if mod.type != 'ARMATURE' and "IGN" not in mod.name:
                if not mod.show_viewport:
                    continue
                bpy.context.view_layer.objects.active = obj
                try:
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                except RuntimeError as e:
                    msg = f"Failed to apply modifier '{mod.name}' ({mod.type}) on object '{obj.name}' in {collection.name}: {e}"
                    print(msg)
                    problems.append(msg)

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
                export_extras=True
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
