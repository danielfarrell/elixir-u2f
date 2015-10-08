defmodule U2F.Crypto do
  @type :sha256

  def digest(data) do
    :crypto.hash(@type, data)
  end

  def sign(data, key) do
    :public_key.sign(data, @type, key)
  end

  def verify(data, signature, key) do
    :public_key.verify(data, @type, signature, key)
  end

  def random(bytes) do
    :crypto.strong_rand_bytes(bytes)
  end

  def generate_key(oid) do
    :public_key.generate_key({@type, oid})
  end

end
