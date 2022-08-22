alias IdentityManager.Users

Enum.each(1..1_000, fn _ ->
  email_verified_at =
    if Enum.random([true, false]) do
      NaiveDateTime.utc_now()
    end

  {:ok, _} =
    Users.insert(%{
      email: Ecto.UUID.generate() <> "@mail.com",
      email_verified_at: email_verified_at
    })
end)
