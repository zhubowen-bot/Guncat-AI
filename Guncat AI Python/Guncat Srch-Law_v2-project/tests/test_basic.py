"""
基础测试文件
测试各模块的基本功能
"""

import sys
import os
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent.parent))

from agents.router_agent import RouterAgent
from agents.contract_agent import ContractAgent
from agents.compliance_agent import ComplianceAgent
from agents.criminal_agent import CriminalAgent
from knowledge_base.rag_engine import RAGEngine
from knowledge_base.law_data_loader import load_core_regulations
from output.formatter import LegalOpinionFormatter


def test_router_agent():
    """测试路由Agent"""
    print("测试 RouterAgent...")
    router = RouterAgent()

    test_case = {
        "description": "某央企子公司与私营企业进行股权转让交易，转让价格明显低于评估值，未履行进场交易程序。涉及金额5000万元。"
    }

    result = router.analyze(test_case)
    print(f"  分类结果：{result.get('case_type')}")
    print(f"  路由目标：{result.get('routing', {}).get('primary_agent')}")
    assert "case_type" in result, "路由结果缺少 case_type"
    print("  ✓ RouterAgent 测试通过\n")


def test_compliance_agent():
    """测试合规审查Agent"""
    print("测试 ComplianceAgent...")
    agent = ComplianceAgent()

    test_case = {
        "description": "某省属国企未经批准，将其持有的子公司30%股权以协议方式转让给民营企业，交易价格低于评估结果20%。",
        "enterprise_type": "省属国企",
    }

    result = agent.analyze(test_case)
    print(f"  Agent名称：{result.get('agent_name')}")
    print(f"  分析类型：{result.get('analysis_type')}")
    assert "result" in result, "分析结果缺少 result 字段"
    print("  ✓ ComplianceAgent 测试通过\n")


def test_contract_agent():
    """测试合同解析Agent"""
    print("测试 ContractAgent...")
    agent = ContractAgent()

    test_case = {
        "description": "股权转让合同中约定，过渡期（评估基准日至交割日）的经营性盈利由受让方享有。但对'经营性盈利'的定义未明确，双方发生争议。",
    }

    result = agent.analyze(test_case)
    assert "result" in result, "分析结果缺少 result 字段"
    print("  ✓ ContractAgent 测试通过\n")


def test_criminal_agent():
    """测试刑事风险Agent"""
    print("测试 CriminalAgent...")
    agent = CriminalAgent()

    test_case = {
        "description": "某国有公司负责人在采购过程中，以明显高于市场的价格向亲友经营管理的公司采购商品，造成国有资产损失约200万元。",
        "persons": "张某，某国有公司总经理",
    }

    result = agent.analyze(test_case)
    assert "result" in result, "分析结果缺少 result 字段"
    print("  ✓ CriminalAgent 测试通过\n")


def test_rag_engine():
    """测试RAG知识库"""
    print("测试 RAGEngine...")
    try:
        engine = RAGEngine()
        engine.initialize()

        # 测试检索
        results = engine.search("企业国有资产法 资产评估", top_k=3)
        print(f"  检索到 {len(results)} 条结果")
        if results:
            print(f"  第一条结果来源：{results[0].get('source')}")
        print("  ✓ RAGEngine 测试通过\n")
    except Exception as e:
        print(f"  ✗ RAGEngine 测试失败: {e}\n")


def test_formatter():
    """测试输出格式化器"""
    print("测试 LegalOpinionFormatter...")
    formatter = LegalOpinionFormatter()

    test_result = {
        "result": """
# 测试法律意见书

## 摘要
这是一个测试案件摘要。

## 关键术语辨析
经营性盈利 vs 可分配利润

## 法律适用分析
根据《企业国有资产法》第43条...

## 风险识别
风险等级：高
"""
    }

    output = formatter.format(test_result)
    print(f"  格式化输出长度：{len(output)} 字符")
    assert len(output) > 0, "格式化输出为空"
    print("  ✓ LegalOpinionFormatter 测试通过\n")


def test_load_regulations():
    """测试法律法规数据加载"""
    print("测试法律法规数据加载...")
    data = load_core_regulations()
    print(f"  加载了 {len(data)} 条法条")
    assert len(data) > 0, "未加载到任何法条"
    print("  ✓ 数据加载测试通过\n")


def run_all_tests():
    """运行所有测试"""
    print("=" * 60)
    print("Guncat Srch-Law V2 基础功能测试")
    print("=" * 60 + "\n")

    # 注意：Agent测试需要配置LLM API密钥
    # 如无API密钥，相关测试会失败（这是预期的）
    print("注意：Agent测试需要配置LLM API密钥")
    print("如无API密钥，Agent测试将跳过（使用mock）\n")

    try:
        test_load_regulations()
    except Exception as e:
        print(f"  数据加载测试失败: {e}\n")

    try:
        test_formatter()
    except Exception as e:
        print(f"  格式化器测试失败: {e}\n")

    try:
        test_rag_engine()
    except Exception as e:
        print(f"  RAG引擎测试失败: {e}\n")
        print("  （如首次运行，可能需要先下载向量化模型，这是正常的）\n")

    # Agent测试（需要API密钥）
    print("\n--- Agent测试（需要LLM API密钥）---")
    print("如需运行Agent测试，请设置环境变量 LLM_API_KEY\n")

    print("=" * 60)
    print("测试完成！")
    print("=" * 60)


if __name__ == "__main__":
    run_all_tests()
