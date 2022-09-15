defprotocol Cypher.Entity do
  @moduledoc false

  @spec dump(any) :: iodata
  def dump(entity)
end
