from .base_platform_tab import BasePlatformTab

class TwitchTab(BasePlatformTab):
    def __init__(self, parent=None):
        super().__init__(
            platform_name="Twitch",
            placeholder="Twitch Clip-, VOD- oder Stream-URL einfügen (z.B. https://www.twitch.tv/videos/... oder clip/...)",
            parent=parent
        )
