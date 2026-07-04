# Generated Firebase DataConnect Client Stub
# This stub allows the backend to start up and run before code-generation is executed.

class MockExecuteResult:
    def __init__(self, data):
        self.data = data

class MockQuery:
    def __init__(self, return_data):
        self.return_data = return_data
    async def execute(self, **kwargs):
        class DataHolder:
            def __init__(self, d):
                for k, v in d.items():
                    if isinstance(v, dict):
                        setattr(self, k, DataHolder(v))
                    elif isinstance(v, list):
                        setattr(self, k, [DataHolder(i) if isinstance(i, dict) else i for i in v])
                    else:
                        setattr(self, k, v)
        return MockExecuteResult(DataHolder(self.return_data))

class MockDataConnectClient:
    def __init__(self):
        self.list_events = MockQuery({"events": []})
        self.get_event = MockQuery({"event": None})
        self.get_user = MockQuery({"user": None})
        self.list_fighters = MockQuery({"fighters": []})
        self.list_gyms = MockQuery({"gyms": []})
        self.get_gym = MockQuery({"gym": None})
        self.search_gyms = MockQuery({"gyms": []})
        self.list_styles = MockQuery({"styles": []})
        self.get_rankings_by_weight_class = MockQuery({"rankings": []})
        self.create_payment = MockQuery({"payment": {"id": "stub_payment_id"}})
        self.list_payouts_for_fighter = MockQuery({"payouts": []})

dc = MockDataConnectClient()
