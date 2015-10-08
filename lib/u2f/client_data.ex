defmodule U2F.ClientData do
  @derive [Poison.Encoder]
  defstruct [:typ, :challenge, :origin]

  def registration_type do
    "navigator.id.finishEnrollment"
  end

  def authentication_type do
    "navigator.id.getAssertion"
  end

  def from_json(json) do
    Poison.decode!(json, as: ClientData)
  end

  def registration?(data) do
    data.typ == registration_type
  end

  def authentication?(data) do
    data.typ == authentication_type
  end

end
