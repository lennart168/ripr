from .base_platform_tab import BasePlatformTab

class TikTokTab(BasePlatformTab):
    def __init__(self, parent=None):
        super().__init__(
            platform_name="TikTok",
            placeholder="TikTok Video-URL einfügen (z.B. https://www.tiktok.com/@user/video/...)",
            parent=parent
        )
