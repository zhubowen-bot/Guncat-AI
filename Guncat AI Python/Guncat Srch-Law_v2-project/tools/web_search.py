"""
WebSearchTool - 联网检索工具
支持实时搜索最新法律法规、司法解释、裁判案例
"""

import requests
from typing import List, Dict, Any, Optional
import json
from datetime import datetime


class WebSearchTool:
    """
    联网检索工具

    功能：
    1. 搜索最新法律法规
    2. 搜索司法解释
    3. 搜索裁判案例
    4. 搜索国资监管最新文件

    注意：实际部署时需要配置有效的搜索API
    可选方案：
    - SerpAPI（Google搜索API）
    - Bing Search API
    - 百度搜索API
    - 直接爬取（需注意合规）
    """

    def __init__(self, api_key: Optional[str] = None, engine: str = "mock"):
        """
        初始化搜索工具

        Args:
            api_key: 搜索API密钥（如配置）
            engine: 搜索引擎类型 ("serpapi" / "bing" / "baidu" / "mock")
        """
        self.api_key = api_key
        self.engine = engine

    def search(
        self,
        query: str,
        max_results: int = 5,
        region: str = "cn",
        time_range: str = "past_2y",
    ) -> List[Dict[str, Any]]:
        """
        执行联网搜索

        Args:
            query: 搜索关键词
            max_results: 返回结果数量
            region: 搜索区域（cn/tw/hk等）
            time_range: 时间范围（past_1y/past_2y/past_5y）

        Returns:
            搜索结果列表，每条包含 title, url, snippet, date 等
        """
        if self.engine == "mock":
            return self._mock_search(query, max_results)
        elif self.engine == "serpapi":
            return self._search_serpapi(query, max_results, region, time_range)
        elif self.engine == "bing":
            return self._search_bing(query, max_results)
        else:
            raise ValueError(f"不支持的搜索引擎: {self.engine}")

    def search_law(
        self,
        law_name: str,
        include_interpretations: bool = True,
    ) -> str:
        """
        专门搜索法律条文（便捷方法）

        Args:
            law_name: 法律名称
            include_interpretations: 是否同时搜索司法解释

        Returns:
            格式化后的搜索结果文本
        """
        # 构建搜索query
        query = f"{law_name} 最新修订 全文"
        results = self.search(query, max_results=3)

        # 格式化
        lines = [f"【{law_name}】相关搜索结果：\n"]
        for i, r in enumerate(results, 1):
            lines.append(f"{i}. {r.get('title', '')}")
            lines.append(f"   来源：{r.get('url', '')}")
            lines.append(f"   摘要：{r.get('snippet', '')}")
            if r.get('date'):
                lines.append(f"   发布日期：{r.get('date')}")
            lines.append("")

        # 搜索司法解释
        if include_interpretations:
            interp_query = f"{law_name} 司法解释 最高人民法院"
            interp_results = self.search(interp_query, max_results=2)
            lines.append(f"\n【{law_name}】司法解释相关搜索结果：\n")
            for i, r in enumerate(interp_results, 1):
                lines.append(f"{i}. {r.get('title', '')}")
                lines.append(f"   来源：{r.get('url', '')}")
                lines.append(f"   摘要：{r.get('snippet', '')}")
                lines.append("")

        return "\n".join(lines)

    def search_case(
        self,
        keywords: str,
        court_level: str = "supreme",  # supreme/high/intermediate
    ) -> str:
        """
        搜索相关裁判案例

        Args:
            keywords: 案例关键词
            court_level: 法院层级

        Returns:
            格式化后的案例搜索结果
        """
        query = f"{keywords} 裁判文书 案例"
        results = self.search(query, max_results=5)

        lines = [f"【{keywords}】相关裁判案例搜索结果：\n"]
        for i, r in enumerate(results, 1):
            lines.append(f"{i}. {r.get('title', '')}")
            lines.append(f"   来源：{r.get('url', '')}")
            lines.append(f"   摘要：{r.get('snippet', '')}")
            lines.append("")

        return "\n".join(lines)

    def search_regulation(
        self,
        agency: str = "国资委",
        doc_type: str = "规范性文件",
    ) -> str:
        """
        搜索监管文件

        Args:
            agency: 发布机关（国资委/财政部/证监会等）
            doc_type: 文件类型

        Returns:
            格式化后的监管文件搜索结果
        """
        query = f"{agency} {doc_type} {datetime.now().year}"
        results = self.search(query, max_results=5)

        lines = [f"【{agency}最新{doc_type}】搜索结果：\n"]
        for i, r in enumerate(results, 1):
            lines.append(f"{i}. {r.get('title', '')}")
            lines.append(f"   来源：{r.get('url', '')}")
            lines.append(f"   摘要：{r.get('snippet', '')}")
            lines.append("")

        return "\n".join(lines)

    def _mock_search(self, query: str, max_results: int) -> List[Dict[str, Any]]:
        """
        Mock搜索（演示用，实际部署时需替换为真实API调用）
        """
        # 返回示例结果
        mock_results = [
            {
                "title": f"关于"{query}"的搜索结果（示例）",
                "url": "https://example.com/law",
                "snippet": "这是示例搜索结果。实际部署时请配置真实的搜索API。",
                "date": datetime.now().strftime("%Y-%m-%d"),
            }
        ]
        return mock_results * min(max_results, 3)

    def _search_serpapi(
        self,
        query: str,
        max_results: int,
        region: str,
        time_range: str,
    ) -> List[Dict[str, Any]]:
        """使用 SerpAPI 执行搜索（需要API Key）"""
        if not self.api_key:
            raise ValueError("使用 SerpAPI 需要配置 API Key")

        params = {
            "q": query,
            "api_key": self.api_key,
            "num": max_results,
            "gl": region,
        }

        # 时间范围映射
        time_map = {
            "past_1y": "y",
            "past_2y": "y2",
            "past_5y": "y5",
        }
        if time_range in time_map:
            params["tbs"] = f"qdr:{time_map[time_range]}"

        try:
            response = requests.get(
                "https://serpapi.com/search",
                params=params,
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()

            results = []
            for item in data.get("organic_results", []):
                results.append({
                    "title": item.get("title", ""),
                    "url": item.get("link", ""),
                    "snippet": item.get("snippet", ""),
                    "date": item.get("date", ""),
                })
            return results
        except Exception as e:
            print(f"SerpAPI 搜索失败: {e}")
            return []

    def _search_bing(self, query: str, max_results: int) -> List[Dict[str, Any]]:
        """使用 Bing Search API 执行搜索（需要API Key）"""
        if not self.api_key:
            raise ValueError("使用 Bing Search API 需要配置 API Key")

        headers = {"Ocp-Apim-Subscription-Key": self.api_key}
        params = {"q": query, "count": max_results, "mkt": "zh-CN"}

        try:
            response = requests.get(
                "https://api.bing.microsoft.com/v7.0/search",
                headers=headers,
                params=params,
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()

            results = []
            for item in data.get("webPages", {}).get("value", []):
                results.append({
                    "title": item.get("name", ""),
                    "url": item.get("url", ""),
                    "snippet": item.get("snippet", ""),
                    "date": item.get("dateLastCrawled", ""),
                })
            return results
        except Exception as e:
            print(f"Bing 搜索失败: {e}")
            return []


# 便捷函数
def search_latest_law(query: str, api_key: Optional[str] = None) -> str:
    """
    便捷函数：搜索最新法律法规

    Args:
        query: 搜索关键词
        api_key: API密钥（可选）

    Returns:
        格式化后的搜索结果
    """
    tool = WebSearchTool(api_key=api_key, engine="mock")  # 默认使用mock
    return tool.search_law(query)


if __name__ == "__main__":
    # 测试
    tool = WebSearchTool(engine="mock")
    results = tool.search("企业国有资产法 最新修订")
    print(f"搜索到 {len(results)} 条结果")
    for r in results:
        print(f"- {r['title']}")
