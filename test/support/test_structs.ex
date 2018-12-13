defmodule Struct1 do
  @moduledoc false
  @fields [field1: nil]

  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end

defmodule Struct2 do
  @moduledoc false
  @fields [field2: nil]

  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end

defmodule Iteraptor.Struct do
  @moduledoc false

  @fields [field: nil]

  @doc false
  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end

# defmodule Iteraptable.Struct do
#   @moduledoc false
#
#   @behaviour Iteraptable
#
#   @name Iteraptable.prefix() <> "struct"
#
#   @impl Iteraptable
#   def dump(%Iteraptor.Struct{} = s), do: %{@name => s}
#   @impl Iteraptable
#   def summon(s), do: s
# end

################################################################################

defprotocol Derivable do
  def ok(a)
end

defimpl Derivable, for: Any do
  defmacro __deriving__(module, struct, _opts) do
    quote do
      defimpl Derivable, for: unquote(module) do
        def ok(arg) do
          {:ok, arg, unquote(Macro.escape(struct))}
        end
      end
    end
  end

  def ok(arg) do
    {:ok, arg}
  end
end

defmodule Iteraptor.DerivedStruct do
  @moduledoc false

  use Iteraptor.Iteraptable, skip: :all, derive: Derivable

  @fields [field: nil]

  @doc false
  def fields, do: @fields
  defstruct @fields
end

defmodule(Iteraptor.BareStruct, do: defstruct(foo: 42, bar: :baz))
