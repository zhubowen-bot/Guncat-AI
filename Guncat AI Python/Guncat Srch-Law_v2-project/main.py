"""
Guncat Srch-Law V2 - 主入口文件

功能：
1. CLI 交互界面
2. 协调各模块（Router/Agent/RAG/Tools/Output）
3. 完整的法律分析工作流
"""

import os
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, Any, List
from datetime import datetime

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from config import MODEL_CONFIG, KNOWLEDGE_BASE_CONFIG, OUTPUT_CONFIG
from agents.router_agent import RouterAgent
from agents.contract_agent import ContractAgent
from agents.compliance_agent import ComplianceAgent
from agents.criminal_agent import CriminalAgent
from knowledge_base.rag_engine import RAGEngine
from tools.web_search import WebSearchTool
from output.formatter import LegalOpinionFormatter


class GuncatSrchLawV2:
    """
    Guncat Srch-Law V2 主系统

    工作流程：
    1. 接收用户输入（案件描述）
    2. 路由Agent分类
    3. 调用RAG检索相关法条
    4. 调用联网搜索获取最新信息
    5. 路由到对应子Agent进行分析
    6. 汇总分析结果
    7. 格式化输出法律意见书
    """

    def __init__(self, llm_api_key: str = None, search_api_key: str = None):
        """
        初始化主系统

        Args:
            llm_api_key: LLM API密钥（如未提供则从环境变量读取）
            search_api_key: 搜索API密钥（如未提供则使用mock模式）
        """
        print("=" * 60)
        print("Guncat Srch-Law V2 国企法律智能分析系统")
        print("=" * 60)

        # 设置API密钥
        if llm_api_key:
            os.environ["LLM_API_KEY"] = llm_api_key
        if search_api_key:
            os.environ["SEARCH_API_KEY"] = search_api_key

        # 初始化各模块
        print("\n[1/4] 初始化路由Agent...")
        self.router = RouterAgent()

        print("[2/4] 初始化子Agent...")
        self.contract_agent = ContractAgent()
        self.compliance_agent = ComplianceAgent()
        self.criminal_agent = CriminalAgent()

        print("[3/4] 初始化RAG知识库...")
        self.rag_engine = RAGEngine(
            vector_store_path=KNOWLEDGE_BASE_CONFIG["vector_store_path"],
            collection_name=KNOWLEDGE_BASE_CONFIG["collection_name"],
        )
        # 初始化知识库（首次运行时会加载数据）
        try:
            self.rag_engine.initialize()
            print(f"  ✓ 知识库初始化完成，当前包含 {self.rag_engine.vector_store.count()} 条法条")
        except Exception as e:
            print(f"  ✗ 知识库初始化失败: {e}")
            print("  → 将跳过RAG检索步骤")

        print("[4/4] 初始化工具模块...")
        self.search_tool = WebSearchTool(
            api_key=search_api_key,
            engine="mock",  # 默认mock模式，配置API密钥后可切换
        )
        self.formatter = LegalOpinionFormatter(
            template_path=OUTPUT_CONFIG["template_path"]
        )

        print("\n系统初始化完成！\n")

    def analyze(self, case_description: str, enterprise_type: str = "不确定") -> Dict[str, Any]:
        """
        执行完整的法律分析工作流

        Args:
            case_description: 案件描述文本
            enterprise_type: 企业类型（央企/省属/市属/区属/不确定）

        Returns:
            完整的分析结果字典
        """
        result = {
            "case_description": case_description,
            "enterprise_type": enterprise_type,
            "timestamp": datetime.now().isoformat(),
            "steps": [],
        }

        # ===== 阶段一：路由分类 =====
        print("\n>>> 阶段一：案件分类...")
        route_result = self.router.analyze({
            "description": case_description,
        })
        result["routing"] = route_result
        primary_agent = route_result.get("routing", {}).get("primary_agent", "comprehensive")
        print(f"  分类结果：{primary_agent}")
        print(f"  置信度：{route_result.get('confidence', 0)}")
        result["steps"].append("routing_done")

        # ===== 阶段二：RAG检索 =====
        print("\n>>> 阶段二：RAG知识库检索...")
        try:
            # 提取关键词（简单方法：取案件描述的前100字作为检索query）
            search_query = case_description[:200]
            rag_results = self.rag_engine.search(
                query=search_query,
                top_k=KNOWLEDGE_BASE_CONFIG["top_k"],
            )
            rag_context = self.rag_engine.format_results(rag_results)
            print(f"  检索到 {len(rag_results)} 条相关法条")
            result["rag_results"] = rag_results
            result["rag_context"] = rag_context
        except Exception as e:
            print(f"  RAG检索失败: {e}")
            result["rag_context"] = ""
        result["steps"].append("rag_done")

        # ===== 阶段三：联网检索 =====
        print("\n>>> 阶段三：联网实时检索...")
        try:
            # 搜索最新法律法规
            search_results = self.search_tool.search(
                query=case_description[:100],
                max_results=3,
            )
            search_context = json.dumps(search_results, ensure_ascii=False, indent=2)
            print(f"  联网检索完成，获取到 {len(search_results)} 条结果")
            result["search_results"] = search_results
            result["search_context"] = search_context
        except Exception as e:
            print(f"  联网检索失败: {e}")
            result["search_context"] = ""
        result["steps"].append("search_done")

        # ===== 阶段四：Agent分析 =====
        print(f"\n>>> 阶段四：调用 {primary_agent} Agent 进行分析...")
        analysis_results = {}

        if primary_agent == "contract":
            analysis = self.contract_agent.analyze({
                "description": case_description,
                "enterprise_type": enterprise_type,
                "rag_context": result.get("rag_context", ""),
                "search_context": result.get("search_context", ""),
            })
            analysis_results["contract"] = analysis

        elif primary_agent == "compliance":
            analysis = self.compliance_agent.analyze({
                "description": case_description,
                "enterprise_type": enterprise_type,
                "rag_context": result.get("rag_context", ""),
                "search_context": result.get("search_context", ""),
            })
            analysis_results["compliance"] = analysis

        elif primary_agent == "criminal":
            analysis = self.criminal_agent.analyze({
                "description": case_description,
                "enterprise_type": enterprise_type,
                "rag_context": result.get("rag_context", ""),
                "search_context": result.get("search_context", ""),
            })
            analysis_results["criminal"] = analysis

        else:  # comprehensive - 综合模式，调用多个Agent
            print("  综合模式：将依次调用多个Agent进行分析...")
            analysis = self.compliance_agent.analyze({
                "description": case_description,
                "enterprise_type": enterprise_type,
                "rag_context": result.get("rag_context", ""),
                "search_context": result.get("search_context", ""),
            })
            analysis_results["compliance"] = analysis

            # 可选：根据需要调用其他Agent
            # analysis_results["contract"] = self.contract_agent.analyze(...)
            # analysis_results["criminal"] = self.criminal_agent.analyze(...)

        result["analysis_results"] = analysis_results
        result["steps"].append("analysis_done")

        # ===== 阶段五：格式化输出 =====
        print("\n>>> 阶段五：生成法律意见书...")
        # 合并所有分析结果
        combined_result = self._combine_results(analysis_results)
        opinion_content = self.formatter.format(combined_result)
        result["opinion_content"] = opinion_content
        result["steps"].append("formatting_done")

        print("\n✓ 分析完成！")
        return result

    def _combine_results(self, analysis_results: Dict[str, Any]) -> Dict[str, Any]:
        """合并多个Agent的分析结果"""
        combined = {"result": ""}

        for agent_name, analysis in analysis_results.items():
            if isinstance(analysis, dict) and "result" in analysis:
                combined["result"] += f"\n\n## {agent_name} 分析结果\n\n"
                combined["result"] += analysis["result"]

        return combined

    def save_opinion(self, result: Dict[str, Any], output_path: str = None, fmt: str = "markdown") -> str:
        """
        保存法律意见书

        Args:
            result: analyze() 的返回结果
            output_path: 输出路径（不含扩展名），None表示自动生成
            fmt: 输出格式（markdown/docx/pdf）

        Returns:
            实际保存的文件路径
        """
        if output_path is None:
            # 自动生成文件名
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = str(Path(OUTPUT_CONFIG["output_dir"]) / f"legal_opinion_{timestamp}")

        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        content = result.get("opinion_content", "")
        if not content:
            content = "分析未完成，无输出内容。"

        saved_path = self.formatter.save(content, output_path, output_format=fmt)
        print(f"\n✓ 法律意见书已保存至：{saved_path}")
        return saved_path

    def interactive_mode(self):
        """交互式CLI模式"""
        print("\n欢迎使用 Guncat Srch-Law V2 交互式分析系统")
        print("输入 'quit' 或 'exit' 退出\n")

        while True:
            print("-" * 60)
            case_desc = input("\n请输入案件描述（或输入 'quit' 退出）：\n> ")
            if case_desc.lower() in ["quit", "exit", "q"]:
                print("感谢使用，再见！")
                break

            enterprise_type = input("\n企业类型（央企/省属/市属/区属/不确定，默认：不确定）：\n> ")
            if not enterprise_type:
                enterprise_type = "不确定"

            # 执行分析
            result = self.analyze(case_desc, enterprise_type)

            # 显示摘要
            print("\n" + "=" * 60)
            print("分析结果摘要：")
            print(result.get("opinion_content", "")[:500] + "...")

            # 询问是否保存
            save = input("\n是否保存完整法律意见书？(y/n，默认：y) > ")
            if save.lower() != "n":
                fmt = input("输出格式（markdown/docx/pdf，默认：markdown）> ")
                if fmt not in ["markdown", "docx", "pdf"]:
                    fmt = "markdown"
                self.save_opinion(result, fmt=fmt)

            print("\n")


def main():
    """命令行入口"""
    parser = argparse.ArgumentParser(
        description="Guncat Srch-Law V2 国企法律智能分析系统"
    )
    parser.add_argument(
        "--mode",
        choices=["interactive", "file"],
        default="interactive",
        help="运行模式：interactive（交互式）或 file（从文件读取案件）",
    )
    parser.add_argument(
        "--input",
        type=str,
        help="案件描述文件路径（file模式下使用）",
    )
    parser.add_argument(
        "--output",
        type=str,
        help="输出文件路径（不含扩展名）",
    )
    parser.add_argument(
        "--format",
        choices=["markdown", "docx", "pdf"],
        default="markdown",
        help="输出格式",
    )
    parser.add_argument(
        "--llm-key",
        type=str,
        help="LLM API密钥",
    )
    parser.add_argument(
        "--search-key",
        type=str,
        help="搜索API密钥",
    )

    args = parser.parse_args()

    # 初始化系统
    system = GuncatSrchLawV2(
        llm_api_key=args.llm_key,
        search_api_key=args.search_key,
    )

    if args.mode == "interactive":
        system.interactive_mode()

    elif args.mode == "file":
        if not args.input:
            print("错误：file模式下必须指定 --input 参数")
            sys.exit(1)

        # 从文件读取案件描述
        with open(args.input, "r", encoding="utf-8") as f:
            case_desc = f.read()

        # 执行分析
        result = system.analyze(case_desc)

        # 保存结果
        output_path = system.save_opinion(result, args.output, args.format)

        print(f"\n分析完成，结果已保存至：{output_path}")


if __name__ == "__main__":
    main()
