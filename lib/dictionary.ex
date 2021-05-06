defmodule Dictionary do
  defmodule Key do
    defstruct(
      version: nil,
      key_name: ""
    )

    @type t :: %Key{
            version: nil | integer,
            key_name: String.t()
          }

    def new(version, key_name), do: %__MODULE__{version: version, key_name: key_name}
  end

  @type key :: {version :: nil | integer(), key_name :: any()}
  @type t :: any()

  @type entry :: any()

  @spec new() :: Dictionary.t()
  def new do
    %{}
  end

  # Add entry to the dictionary under the key, with specific version.
  # Returns an error when key with same key_name and version is already present.
  #
  # Version cannot be nil.
  @spec append(Dictionary.t(), key, entry) :: {:ok, t} | {:error, any()}
  def append(_dict, nil, _entry) do
    {:error, :must_specify_key}
  end

  # available in Elixir 1.10=<
  # %{%Key{version: 1, key_name: "test"} => :my_value}
  # %{:key => :my_value}
  def append(dict, key, entry) when is_map_key(dict, key) do
    {:error, :single_entry_only}
  end

  def append(dict, key, entry) do
    key =
      case key do
        %Key{} -> key
        %{version: _, key_name: _} = key -> Map.put(key, :__struct__, Key)
      end

    Map.put(dict, key, entry)
  end

  # Returns the earliest entry for given key if version nil.
  # Otherwise returns request version if found.
  @spec get(t, key) :: {:ok, t} | {:error, :not_found}
  def get(dict, %Key{version: nil, key_name: key_name} = key) do
    {_, value} =
      dict
      |> Enum.into([])
      |> Enum.filter(fn
        {%Key{key_name: ^key_name}, _v} ->
          true

        _ ->
          false
      end)
      |> Enum.max_by(fn {%{version: version}, v} ->
        version
      end)

    {:ok, value}
  end

  def get(dict, key) do
    case Map.get(dict, key) do
      nil ->
        {:error, :not_found}

      value ->
        value
    end
  end

  # Combines two dictionaries with respect to history of each key. If entry
  # is duplicate merge can proceed only if values are equal.
  @spec merge(t, t) :: {:ok, t} | {:error, any()}
  def merge(dict1, dict2) do
    try do
      result =
        Map.merge(dict1, dict2, fn
          _k, v1, v1 ->
            v1

          _k, _v1, _v2 ->
            throw(:merge_conflict)
        end)

      {:ok, result}
    catch
      :merge_conflict ->
        {:error, :merge_conflict}
    end
  end

  # dict = Dictionary.new()

  # dict1 = Dictionary.append(dict, Dictionary.Key.new(1, :a), :b)
  # dict2 = Dictionary.append(dict, Dictionary.Key.new(2, :a), :e)
  # dict = Dictionary.append(dict, Dictionary.Key.new(2, :a), :different)

  # IO.puts inspect dict

  # dict  = Dictionary.get(dict, {nil, :a})

  # {:ok, merged} = Dictionary.merge(dict1, dict2)

  # IO.puts inspect Dictionary.get(merged, Dictionary.Key.new(nil, :a))
  # IO.puts inspect Dictionary.get(merged, Dictionary.Key.new(1, :a))

  # for _ <- 1..5, do: IO.puts "Hello, World!"
end
