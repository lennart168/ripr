from .base_platform_tab import BasePlatformTab

class YouTubeTab(BasePlatformTab):
    def __init__(self, parent=None):
        super().__init__(
            platform_name="YouTube",
            placeholder="YouTube Video- oder Shorts-URL einfügen (z.B. https://www.youtube.com/watch?v=...)",
            parent=parent
        )
