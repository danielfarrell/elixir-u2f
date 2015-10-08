defmodule U2F.SignResponse do
  defstruct [:client_data, :key_handle, :signature_data]

  def load_from_json(json) do
    data = Poison.Parser.parse!(json)
    client_data_json = U2F.Base64.decode(data["clientData"])

    %SignResponse{client_data: ClientData.from_json(client_data_json), key_handle: data["keyHandle"], signature_data: U2F.Base64.decode(data["signatureData"])}
  end

  ##
  # Counter value that the U2F token increments every time it performs an
  # authentication operation
  def counter(response) do
    response.signature_data[1..4].unpack('N').first
  end

  ##
  # signature is to be verified using the public key obtained during
  # registration.
  def signature(response) do
    response.signature_data.byteslice(5..-1)
  end

  ##
  # If user presence was verified
  def user_present?(response) do
    response.signature_data[0].unpack('C').first == 1
  end

  ##
  # Verifies the response against an app id and the public key of the
  # registered device
  def verify(response, app_id, public_key_pem) do
    # data = [
    #   ::U2F::DIGEST.digest(app_id),
    #   response.signature_data.byteslice(0, 5),
    #   ::U2F::DIGEST.digest(client_data_json)
    # ] |> Enum.join
    #
    # public_key = OpenSSL::PKey.read(public_key_pem)
    # public_key.verify(::U2F::DIGEST.new, signature, data)
  end

end
