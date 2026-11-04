extends ProjectileBase

@export var trailWidth := 4.
@export var trailTime := 5.
@export var trailMaterial : Material

var host: TrailHost


# Owns the trail meshes so they keep updating after the projectile is reflected or freed.
class TrailHost extends Node3D:
	class Segment:
		var mesh: MeshInstance3D
		var cyl: CylinderMesh
		var anchor: Node3D
		var anchorLocal: Vector3
		var startWorld: Vector3
		var endWorld: Vector3
		var closed := false
		var age := 0.
		var tailDetached := false
		var sphere: MeshInstance3D
		var endAnchor: Node3D
		var endLocal: Vector3
		var prevEnd: Vector3

	var segments: Array[Segment] = []
	var projectile: Node3D
	var material: Material
	var width := 4.
	var time := 5.
	var speed := 500.
	var lastHead := Vector3.ZERO
	var headAlive := true

	func _make_mesh(m: Mesh) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		return mi

	func begin_segment(pos: Vector3, anchor: Node3D) -> void:
		var s := Segment.new()
		s.cyl = CylinderMesh.new()
		s.cyl.radial_segments = 12
		s.cyl.rings = 1
		s.cyl.top_radius = width * .5
		s.cyl.bottom_radius = width * .5
		s.mesh = _make_mesh(s.cyl)
		s.startWorld = pos
		s.endWorld = pos
		if is_instance_valid(anchor):
			s.anchor = anchor
			s.anchorLocal = anchor.to_local(pos)
		segments.append(s)

	func close_current(pos: Vector3, endAnchor: Node3D = null) -> void:
		if segments.is_empty():
			return
		var s: Segment = segments.back()
		if s.closed:
			return
		s.closed = true
		s.endWorld = pos
		s.prevEnd = pos
		if is_instance_valid(endAnchor):
			s.endAnchor = endAnchor
			s.endLocal = endAnchor.to_local(pos)
		var sph := SphereMesh.new()
		sph.radius = width * .5
		sph.height = width
		s.sphere = _make_mesh(sph)
		s.sphere.global_position = pos

	func _physics_process(delta: float) -> void:
		var head := lastHead
		if headAlive:
			if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
				head = projectile.global_position
			else:
				headAlive = false
				close_current(lastHead)
		var move := head - lastHead
		lastHead = head

		var headRadius := width * .5
		for s: Segment in segments.duplicate():
			s.age += delta
			var tailRadius := headRadius * maxf(0., 1. - s.age / time)

			var endMove := Vector3.ZERO
			if not s.closed:
				s.endWorld = head
			elif is_instance_valid(s.endAnchor):
				s.endWorld = s.endAnchor.to_global(s.endLocal)
				endMove = s.endWorld - s.prevEnd
			s.prevEnd = s.endWorld
			if s.sphere:
				s.sphere.global_position = s.endWorld

			if s.tailDetached:
				if not s.closed:
					s.startWorld += move
				else:
					s.startWorld += endMove
					var dir := s.endWorld - s.startWorld
					var step := speed * delta
					if dir.length() <= step:
						_free_segment(s)
						continue
					s.startWorld += dir.normalized() * step
			elif tailRadius <= 0.:
				s.tailDetached = true
				s.startWorld = _segment_start(s)
			else:
				s.startWorld = _segment_start(s)

			_apply_segment(s, tailRadius, headRadius)

		if not headAlive and segments.is_empty():
			queue_free()

	func _segment_start(s: Segment) -> Vector3:
		if is_instance_valid(s.anchor):
			return s.anchor.to_global(s.anchorLocal)
		return s.startWorld

	func _apply_segment(s: Segment, tailRadius: float, headRadius: float) -> void:
		var d := s.endWorld - s.startWorld
		var length := d.length()
		if length < 0.001:
			s.mesh.visible = false
			return
		s.mesh.visible = true
		s.cyl.height = length
		s.cyl.top_radius = headRadius
		s.cyl.bottom_radius = tailRadius
		var up := d / length
		var q := Quaternion(Vector3.UP, up) if not up.is_equal_approx(Vector3.DOWN) \
			else Quaternion(Vector3.RIGHT, PI)
		s.mesh.global_transform = Transform3D(Basis(q), s.startWorld + d * .5)

	func _free_segment(s: Segment) -> void:
		s.mesh.queue_free()
		if s.sphere:
			s.sphere.queue_free()
		segments.erase(s)


func _ready() -> void:
	var src := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if src:
		if src.material_override:
			trailMaterial = src.material_override
		elif src.mesh and src.mesh.get_surface_count() > 0:
			trailMaterial = src.mesh.surface_get_material(0)


func _ensure_host() -> void:
	if host:
		return
	# Spawner sets position after add_child, so start the trail on the first physics frame
	host = TrailHost.new()
	host.top_level = true
	host.projectile = self
	host.material = trailMaterial
	host.width = trailWidth
	host.time = trailTime
	host.speed = speed
	host.lastHead = global_position
	get_parent().add_child(host)
	host.global_transform = Transform3D.IDENTITY
	host.begin_segment(global_position, attacker)


func _deflect(defender: Node3D) -> void:
	_ensure_host()
	host.close_current(global_position, defender)
	super(defender)
	host.begin_segment(global_position, attacker)


func _physics_process(delta: float) -> void:
	_ensure_host()
	super(delta)
