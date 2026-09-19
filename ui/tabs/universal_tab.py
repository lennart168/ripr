from .base_platform_tab import BasePlatformTab

class UniversalTab(BasePlatformTab):
    def __init__(self, parent=None):
        super().__init__(
            platform_name="Universal",
            placeholder="Jede beliebige Video-URL einfügen (Twitter/X, Reddit, Vimeo, Facebook, etc.)",
            parent=parent
        )
