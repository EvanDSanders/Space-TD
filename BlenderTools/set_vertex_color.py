"""Blender script: set a VertexColor color attribute on all selected mesh objects.

Run inside Blender's Python console / Text Editor, or via the Blender MCP
execute_blender_code tool.
"""

import bpy


def set_vertex_color(hex_color="#FF0000", layer_name="VertexColor"):
    """Add/overwrite a byte-color attribute named `layer_name` on every
    selected mesh object, filling it with `hex_color` (e.g. "#FF0000")."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0
    a = 1.0

    selected = [obj for obj in bpy.context.selected_objects if obj.type == 'MESH']
    if not selected:
        return "No mesh objects selected."

    changed = []
    for obj in selected:
        mesh = obj.data

        color_attrs = mesh.color_attributes
        existing = color_attrs.get(layer_name)
        if existing:
            color_attrs.remove(existing)

        attr = color_attrs.new(name=layer_name, type='BYTE_COLOR', domain='CORNER')
        for c in attr.data:
            c.color = (r, g, b, a)

        color_attrs.active_color = attr
        changed.append(obj.name)

    return f"Set '{layer_name}' to {hex_color} on: {changed}"


if __name__ == "__main__":
    print(set_vertex_color(hex_color="#FF0000", layer_name="VertexColor"))
