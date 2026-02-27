class_name FlecsTest extends Node

# Just a generic comp with a bunch of data
class TestComponent:
	var floating: float
	var text: String
	var boolean: bool
	var vector: Vector3

class RefInt:
	var value: int

	func _init(p_value: int) -> void:
		self.value = p_value
	
	func reset():
		self.value = 0

const TEST_COMP_NAME := "TestComponent"

var DESCENDS_FROM : RID
var root_entity: RID
var first_frame: bool = true
var query_dict : Dictionary[String, Query] = {}
var deleted_root_entity: bool = false
var elapsed: float

func component_set_active() -> void:
	var ent := FlecsScene.create_raw_entity();
	FlecsScene.entity_add_component_instance(ent, TEST_COMP_NAME, TestComponent.new())
	var is_active := FlecsScene.entity_is_component_active(ent, TEST_COMP_NAME)

	assert(is_active)

	var query := Query.new()
	query.with(TEST_COMP_NAME)

	var query_hit_count := RefInt.new(0)

	query.each(func _iter(_entity: RID, _comps: Array):
		query_hit_count.value += 1
	)

	assert(query_hit_count.value == 1)

	query_hit_count.reset()
	FlecsScene.entity_set_component_active(ent, TEST_COMP_NAME, false)

	query.each(func _iter(_entity: RID, _comps: Array):
		query_hit_count.value += 1
	)
	
	assert(query_hit_count.value == 0, "Query should not hit on disabled component")


func component_set_active_with_duplicate() -> void:
	# Create an entity, turn off its comp, turn it back on and then duplicate it
	var ent := FlecsScene.create_raw_entity();
	FlecsScene.entity_add_component_instance(ent, TEST_COMP_NAME, TestComponent.new())
	

	var query := Query.new()
	query.with(TEST_COMP_NAME)

	var query_hit_count := RefInt.new(0)

	query.each(func _iter(_entity: RID, _comps: Array):
		query_hit_count.value += 1
	)

	assert(query_hit_count.value == 1)

	query_hit_count.reset()
	FlecsScene.entity_set_component_active(ent, TEST_COMP_NAME, false)

	query.each(func _iter(_entity: RID, _comps: Array):
		query_hit_count.value += 1
	)
	
	assert(query_hit_count.value == 0, "Query should not hit on disabled component")

	query_hit_count.reset()
	FlecsScene.entity_set_component_active(ent, TEST_COMP_NAME, true)
	var clone := FlecsScene.entity_duplicate(ent)
	
	query.each(func _iter(_entity: RID, _comps: Array):
		query_hit_count.value += 1
	)

	assert(query_hit_count.value == 2, "Query should hit both entities with duplicated data")

func add_child_with_descends(parent: RID, child: RID):
	if !DESCENDS_FROM.is_valid():
		DESCENDS_FROM = FlecsScene.create_raw_entity_with_tag("DESCENDS_FROM")

	# Traverse all parents
	FlecsScene.entity_add_child(parent, child)
	FlecsScene.entity_add_relation(child, DESCENDS_FROM, parent)

	var grandparent := FlecsScene.entity_get_parent(parent)
	while grandparent.is_valid():
		FlecsScene.entity_add_relation(child, DESCENDS_FROM, grandparent)
		grandparent = FlecsScene.entity_get_parent(grandparent)


func _save_load_generic_array():
	const tag := "ArrayHolder"
	var ent := FlecsScene.create_raw_entity_with_tag(tag)

	FlecsScene.register_gdscript_primitive_component_serializer("Arr", TYPE_ARRAY)
	FlecsScene.entity_add_component_instance(ent, "Arr", [])
	FlecsScene.entity_set_component_active(ent, "Arr", false)
	# FlecsScene.entity_add_component_instance(ent, "Arr", [rid_from_int64(23), rid_from_int64(1), rid_from_int64(4)])
	# FlecsScene.entity_set_component_active(ent, "Arr", true)
	FlecsScene.save_scene("generic_arr_world.json")

	FlecsScene.destroy_raw_entity_immediate(ent)

	FlecsScene.load_scene("generic_arr_world.json")
	ent = FlecsScene.create_raw_entity_with_tag(tag)
	var array_comp : Array = FlecsScene.get_component_from_entity(ent, "Arr")
	assert(array_comp != null && array_comp.is_empty(), "Failed to fetch array or data is invalid")


func _nested_query_test():
	if (self.first_frame):
		self.root_entity = FlecsScene.create_raw_entity_with_tag("ROOT")

		var child := FlecsScene.create_raw_entity()
		var nested_child := FlecsScene.create_raw_entity()

		add_child_with_descends(self.root_entity, child)
		add_child_with_descends(child, nested_child)

	if (self.deleted_root_entity):
		assert(!FlecsScene.entity_is_alive(self.root_entity), "Entity was not deleted!")

	const key := "TOP_QUERY"
	var top_query = self.query_dict.get(key)

	if (typeof(top_query) == TYPE_NIL):
		top_query = Query.new()
		top_query.cache_mode(Query.None)

		top_query.with_relation(DESCENDS_FROM, self.root_entity)
		self.query_dict.get_or_add(key, top_query)

	top_query.each_entity(func _iter(entity: RID):
		print(Time.get_time_string_from_system(), " Matched on entity: ", entity)
	)

	if (self.elapsed > 4 && !self.deleted_root_entity):
		self.deleted_root_entity = true
		# Delete the root entity first
		FlecsScene.destroy_raw_entity(self.root_entity)
		self.query_dict.erase(key)

func _process(delta: float) -> void:
	self.elapsed += delta
	self._nested_query_test()
	if (self.first_frame):
		self.first_frame = false



func _ready() -> void:
	component_set_active()
	component_set_active_with_duplicate()
	_save_load_generic_array()
