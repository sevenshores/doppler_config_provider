defmodule DopplerConfigProviderTest do
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  @doppler_body """
  {
    "STRIPE_SECRET": "sk_test_9YxLnoLDdvOPn2dfjBVPB",
    "STRIPE_PUBLIC": "pk_test_9YxLnoLDdvOPn2dfjBVPB",
    "DATABASE_URL": "postgres://brian@aws.dynamodb.com:5432/db_test"
  }
  """

  @doppler_body_extra """
  {
    "STRIPE_SECRET": "sk_test_9YxLnoLDdvOPn2dfjBVPB",
    "STRIPE_PUBLIC": "pk_test_9YxLnoLDdvOPn2dfjBVPB",
    "DATABASE_URL": "postgres://brian@aws.dynamodb.com:5432/db_test",
    "FOOBAR": "baz"
  }
  """

  @doppler_body_401 ~s({"messages": ["Invalid Auth token"], "success": false})

  setup do
    app_config = [
      doppler_config_provider: [
        {DopplerConfigProvider.Repo, pool_size: 20}
      ]
    ]

    {:ok, app_config: app_config}
  end

  test "init/1 passes through the opts" do
    assert DopplerConfigProvider.init(foo: :bar) == [foo: :bar]
  end

  test "merges config with default values", %{app_config: app_config} do
    expect(Mojito, :request, fn :get, _url, _headers ->
      {:ok, %{status_code: 200, body: @doppler_body}}
    end)

    opts = [
      service_token: "foobar",
      mappings: %{
        "STRIPE_SECRET" => [:stripity_stripe, :api_key],
        "STRIPE_PUBLIC" => [:stripity_stripe, :public_key],
        "DATABASE_URL" => [:doppler_config_provider, DopplerConfigProvider.Repo, :url]
      }
    ]

    assert config = DopplerConfigProvider.load(app_config, opts)

    assert config == [
             doppler_config_provider: [
               {DopplerConfigProvider.Repo,
                [
                  pool_size: 20,
                  url: "postgres://brian@aws.dynamodb.com:5432/db_test"
                ]}
             ],
             stripity_stripe: [
               {:public_key, "pk_test_9YxLnoLDdvOPn2dfjBVPB"},
               {:api_key, "sk_test_9YxLnoLDdvOPn2dfjBVPB"}
             ]
           ]
  end

  test "merges config with warnings", %{app_config: app_config} do
    service_token = "foobar"
    expected_headers = [{"authorization", "Basic " <> Base.encode64(service_token <> ":")}]

    expect(Mojito, :request, fn :get, _url, ^expected_headers ->
      {:ok, %{status_code: 200, body: @doppler_body_extra}}
    end)

    opts = [
      service_token: service_token,
      http_module: Mojito,
      json_module: Jason,
      mappings: %{
        "STRIPE_SECRET" => [:stripity_stripe, :api_key],
        "STRIPE_PUBLIC" => [:stripity_stripe, :public_key],
        "DATABASE_URL" => [:doppler_config_provider, DopplerConfigProvider.Repo, :url]
      }
    ]

    log =
      capture_log(fn ->
        assert config = DopplerConfigProvider.load(app_config, opts)

        assert config == [
                 doppler_config_provider: [
                   {DopplerConfigProvider.Repo,
                    [
                      pool_size: 20,
                      url: "postgres://brian@aws.dynamodb.com:5432/db_test"
                    ]}
                 ],
                 stripity_stripe: [
                   {:public_key, "pk_test_9YxLnoLDdvOPn2dfjBVPB"},
                   {:api_key, "sk_test_9YxLnoLDdvOPn2dfjBVPB"}
                 ]
               ]
      end)

    assert log =~ "[DopplerConfigProvider] Unhandled Doppler config: `FOOBAR`"
  end

  test "raises error when doppler API returns error status", %{app_config: app_config} do
    expect(Mojito, :request, fn :get, _url, _headers ->
      {:ok, %{status_code: 401, body: @doppler_body_401}}
    end)

    opts = [
      service_token: "notvalid",
      mappings: %{
        "STRIPE_SECRET" => [:stripity_stripe, :api_key],
        "STRIPE_PUBLIC" => [:stripity_stripe, :public_key],
        "DATABASE_URL" => [:doppler_config_provider, DopplerConfigProvider.Repo, :url]
      }
    ]

    assert_raise RuntimeError, ~r/Unable to fetch Doppler config:/, fn ->
      DopplerConfigProvider.load(app_config, opts)
    end
  end

  test "raises an error when no :http_module and no default dependency", %{app_config: app_config} do
    reject(&Mojito.request/3)

    DopplerConfigProvider.Util
    |> stub(:ensure_loaded?, fn _ -> true end)
    |> expect(:ensure_loaded?, fn Mojito -> false end)

    opts = [
      service_token: "foobar",
      mappings: %{
        "STRIPE_SECRET" => [:stripity_stripe, :api_key],
        "STRIPE_PUBLIC" => [:stripity_stripe, :public_key],
        "DATABASE_URL" => [:doppler_config_provider, DopplerConfigProvider.Repo, :url]
      }
    ]

    assert_raise ArgumentError, "Must include :http_module, or add :mojito as a dependency", fn ->
      DopplerConfigProvider.load(app_config, opts)
    end
  end

  test "raises an error when no :json_module and no default dependency", %{app_config: app_config} do
    reject(&Mojito.request/3)

    DopplerConfigProvider.Util
    |> stub(:ensure_loaded?, fn _ -> true end)
    |> expect(:ensure_loaded?, fn Mojito -> true end)
    |> expect(:ensure_loaded?, fn Jason -> false end)
    |> expect(:ensure_loaded?, fn Poison -> false end)

    opts = [
      service_token: "foobar",
      mappings: %{
        "STRIPE_SECRET" => [:stripity_stripe, :api_key],
        "STRIPE_PUBLIC" => [:stripity_stripe, :public_key],
        "DATABASE_URL" => [:doppler_config_provider, DopplerConfigProvider.Repo, :url]
      }
    ]

    assert_raise ArgumentError,
                 "Must include :json_module, or add :jason or :poison as a dependency",
                 fn ->
                   DopplerConfigProvider.load(app_config, opts)
                 end
  end
end
