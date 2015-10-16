defmodule Entice.Logic.CoordinationTest do
  use ExUnit.Case, async: true
  alias Entice.Entity.Coordination
  alias Entice.Entity
  alias Entice.Entity.Test.Spy

  defmodule TestAttr1, do: defstruct foo: 1337, bar: "lol"
  defmodule TestAttr2, do: defstruct baz: false
  defmodule TestAttr3, do: defstruct crux: "hello"


  setup do
    {:ok, eid, _pid} = Entity.start

    Entity.put_attribute(eid, %TestAttr1{})
    Entity.put_attribute(eid, %TestAttr2{})

    {:ok, [entity_id: eid]}
  end


  test "entity notification", %{entity_id: eid} do
    Spy.register(eid, self)
    assert :ok = Coordination.notify(eid, :something)
    assert_receive %{sender: ^eid, event: :something}
  end


  test "notification of all entities" do
    {:ok, id1, e1} = Entity.start
    {:ok, id2, e2} = Entity.start
    {:ok, id3, e3} = Entity.start
    Spy.register(e1, self)
    Spy.register(e2, self)
    Spy.register(e3, self)

    Coordination.notify_all(:test_message)

    assert_receive %{sender: ^id1, event: :test_message}
    assert_receive %{sender: ^id2, event: :test_message}
    assert_receive %{sender: ^id3, event: :test_message}
  end


  test "observer registry", %{entity_id: eid} do
    Coordination.register_observer(self())
    assert_receive {:entity_join, %{
      entity_id: ^eid,
      attributes: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}}}}
  end


  test "add attributes", %{entity_id: eid} do
    Coordination.register_observer(self())
    Entity.put_attribute(eid, %TestAttr3{})
    assert_receive {:entity_change, %{
      entity_id: ^eid,
      added: %{TestAttr3 => %TestAttr3{}},
      changed: %{},
      removed: %{}}}
  end


  test "change attributes", %{entity_id: eid} do
    Coordination.register_observer(self())
    Entity.put_attribute(eid, %TestAttr1{foo: 42})
    assert_receive {:entity_change, %{
      entity_id: ^eid,
      added: %{},
      changed: %{TestAttr1 => %TestAttr1{foo: 42}},
      removed: %{}}}
  end


  test "delete attributes", %{entity_id: eid} do
    Coordination.register_observer(self())
    Entity.remove_attribute(eid, TestAttr1)
    assert_receive {:entity_change, %{
      entity_id: ^eid,
      added: %{},
      changed: %{},
      removed: %{TestAttr1 => %TestAttr1{}}}}
  end


  test "entity join" do
    Coordination.register_observer(self())
    {:ok, eid2, _pid} = Entity.start_plain()
    Coordination.register(eid2)
    assert_receive {:entity_join, %{
      entity_id: ^eid2,
      attributes: %{}}}
  end


  test "entity leave", %{entity_id: eid} do
    Coordination.register_observer(self())
    Entity.stop(eid)
    assert_receive {:entity_leave, %{
      entity_id: ^eid,
      attributes: %{
        TestAttr1 => %TestAttr1{},
        TestAttr2 => %TestAttr2{}}}}
  end
end
