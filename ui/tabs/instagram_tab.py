from .base_platform_tab import BasePlatformTab

class InstagramTab(BasePlatformTab):
    def __init__(self, parent=None):
        super().__init__(
            platform_name="Instagram",
            placeholder="Instagram Reel- oder Post-URL einfügen (z.B. https://www.instagram.com/reel/...)",
            parent=parent
        )
