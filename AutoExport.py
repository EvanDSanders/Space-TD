import os
import bpy

def find_collection(name: str):
    for collection in bpy.data.collections:
        if collection.name == name:
            return collection
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

def export_collection(collection, export_dir):
    objects = collection_objects(collection)
    if not objects:
        print(f"Skipping empty collection: {collection.name}")
        return

    origin = find_origin_object(objects)
    if origin is None:
        print(f"Skipping {collection.name}: no object starting with 'Origin.'")
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

    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]

    export_name = collection.name.replace(".", " ")
    filepath = os.path.join(export_dir, f"./Objects/{export_name}.glb")

    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format="GLB",
        use_selection=True,
        export_apply=False,
        export_skins=True,
        export_all_influences=True,
        export_morph=False,
        export_animations=False,
    )
    print(f"Exported {filepath}")

def main():
    export_dir = os.path.dirname(os.path.abspath(__file__))

    auto_export = find_collection("Auto Export")
    if auto_export is None:
        raise RuntimeError("Collection 'Auto Export' not found")

    for collection in auto_export.children:
        export_collection(collection, export_dir)

if __name__ == "__main__":
    main()
