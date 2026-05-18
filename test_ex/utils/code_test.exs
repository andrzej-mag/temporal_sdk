defmodule TemporalSdk.Utils.CodeTest do
  use ExUnit.Case
  doctest TemporalSdk.Utils.Code

  import TemporalSdk.Utils.Code

  test "translate_doc" do
    assert translate_doc("`atom`") == "`:atom`"
    assert translate_doc("```atom```") == "```atom```"
    assert translate_doc("Text `atom` text.") == "Text `:atom` text."
    assert translate_doc("Text ```atom``` text.") == "Text ```atom``` text."

    assert translate_doc("(https://hexdocs.pm/temporal_sdk_samples/hello_world.html)") ==
             "(https://hexdocs.pm/temporal_sdk_samples/HelloWorld.html)"

    assert translate_doc("(https://hexdocs.pm/temporal_sdk_samples/simple.html)") ==
             "(https://hexdocs.pm/temporal_sdk_samples/Simple.html)"
  end

  test "atom" do
    assert ts("atom") == ":atom"
    assert ts("true") == "true"
    assert ts("temporal_sdk") == ":temporal_sdk"
    assert ts("temporal_sdk_cluster") == ":temporal_sdk_cluster"
  end

  test "list" do
    assert ts("[]") == "[]"
    assert ts("[a1, a2, a3]") == "[:a1, :a2, :a3]"
  end

  test "local" do
    assert ts("m:module") == "m::module"
    assert ts("m:module#section_ref") == "m::module#section_ref"
    assert ts("function/3") == "function/3"
  end

  test "external" do
    assert ts("e:module") == "e::module"
    assert ts("e:module#section_ref") == "e::module#section_ref"
    assert ts("e:module:test.md#section_ref") == "e:module:test.md#section_ref"
    assert ts("e:my_mod:func/3") == "e::my_mod.func/3"
  end

  test "map" do
    assert ts("\#{}") == "%{}"
    assert ts("\#{k => v}") == "%{k: :v}"
  end

  test "remote type" do
    assert ts("c:my_module:type/0") == "c::my_module.type/0"
    assert ts("e:my_module:type/0") == "e::my_module.type/0"
    assert ts("t:my_module:type/0") == "t::my_module.type/0"
  end

  test "remote function" do
    assert ts("my_mod:func/3") == ":my_mod.func/3"
  end

  test "string" do
    assert ts("\"string_string\"") == "\"string_string\""
  end

  test "binary" do
    assert ts("~\"binary\"") == "binary"
  end

  test "tuple" do
    assert ts("{ok, error}") == "{:ok, :error}"
  end

  test "type" do
    assert ts("map()") == "map()"
  end

  test "variable" do
    assert ts("MyVariable") == "my_variable"
  end

  test "number" do
    assert ts("1234") == "1234"
    assert ts("1.234") == "1.234"
  end

  test "SDK specific" do
    assert ts("m:temporal_sdk") == "m:TemporalSdk"
    assert ts("m:temporal_sdk#section_ref") == "m:TemporalSdk#section_ref"
    assert ts("e:temporal_sdk") == "e:TemporalSdk"
    assert ts("e:temporal_sdk#section_ref") == "e:TemporalSdk#section_ref"
    assert ts("e:temporal_sdk:test.md#section_ref") == "e:temporal_sdk:test.md#section_ref"

    assert ts("m:temporal_sdk_cluster") == "m:TemporalSdk.Cluster"
    assert ts("m:temporal_sdk_cluster#section_ref") == "m:TemporalSdk.Cluster#section_ref"
    assert ts("e:temporal_sdk_cluster") == "e:TemporalSdk.Cluster"
    assert ts("e:temporal_sdk_cluster#section_ref") == "e:TemporalSdk.Cluster#section_ref"
    assert ts("e:temporal_sdk_cluster:t.md#section") == "e:temporal_sdk_cluster:t.md#section"

    assert ts("temporal_sdk:func/3") == "TemporalSdk.func/3"
    assert ts("temporal_sdk_cluster:func/3") == "TemporalSdk.Cluster.func/3"
  end
end
