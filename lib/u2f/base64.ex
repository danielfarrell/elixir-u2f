defmodule U2F.Base64 do
  def decode(string) do
    length = String.length(string)
    string = case rem(length, 4) do
       2 ->
         string <> "=="
       3 ->
         string <> "="
       _ ->
         string
     end
    Base.url_decode64(string)
  end

  def encode(string) do
    Base.url_encode64(string) |> String.replace("=", "")
  end
end
