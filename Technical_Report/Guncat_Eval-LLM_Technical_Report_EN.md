# Anti-Hallucination Architecture: Design and Prompt Engineering of Guncat Eval-LLM, a Large Model Evaluation Intelligence Analyst

**Open-Source Technical Report**

---

## Abstract

The rapid iteration of large language models (LLMs)—with major updates arriving every 2–4 weeks on average—makes "model comparison" one of the most challenging propositions in anti-hallucination tasks. Mainstream models universally exhibit systematic biases including version confusion, training-data lag, and defaulting to legacy models (e.g., GPT-4 era) as the strongest. These biases cause model comparison conclusions to be frequently distorted. This paper introduces **Guncat Eval-LLM**, an open-source agent designed as a large model evaluation intelligence analyst, detailing its design and prompt engineering. The agent employs a 12-step workflow and eight key anti-hallucination mechanisms, constructing a three-tier anti-inflation system covering information acquisition, benchmark anchoring, and intelligence estimation. This paper systematically presents the five typical hallucination patterns in model comparison, their corresponding countermeasures, the iterative prompt engineering methodology (failure-node-analysis-driven improvement + anti-overfitting principles), and the three-tier collaborative anti-inflation system design. The agent and its prompt engineering methodology are open-sourced to provide the community with a reproducible reference implementation for anti-hallucination.

**Keywords**: Large Language Model Evaluation; Anti-Hallucination; Prompt Engineering; Retrieval-Augmented Generation; Model Comparison; Cognitive Bias

---

## 1. Introduction: Model Comparison as the Quintessential Anti-Hallucination Proposition

### 1.1 Problem Statement

The capability assessment of large language models has experienced explosive growth in 2024–2026. New models emerge at a pace of one major release every 2–4 weeks, each claiming to be "the strongest" or "breakthrough" on one or more benchmarks. Yet the true capability landscape of models has become increasingly obscured—on one hand, vendor marketing rhetoric has inflated; on the other, evaluation benchmarks themselves iterate rapidly and suffer from contamination. In this environment, the seemingly simple question "What model is Model A equivalent to today?" is in fact one of the most hallucination-prone propositions in LLM applications.

Guncat Eval-LLM is an open-source agent designed precisely to address this problem. Its core mission is to filter noise for users, identify timeliness, restore the true picture of model capabilities, and explicitly declare uncertainty when information is incomplete—never fabricating. This paper systematically documents the agent's design philosophy, prompt engineering methodology, and the anti-inflation system formed through three rounds of iteration.

### 1.2 Why Model Comparison Is the Quintessential Anti-Hallucination Proposition

Model comparison qualifies as the quintessential anti-hallucination proposition due to five structural challenges that LLMs face when handling such tasks:

**First, training-data lag.** Large models have a clear training data cutoff, while the model ecosystem iterates at a 2–4 week pace. Any model released or updated after the training cutoff is essentially unknown to the LLM, or its knowledge is outdated. When a user asks "What is Model A equivalent to?", the LLM tends to answer using stale knowledge from training memory rather than acknowledging the knowledge gap and performing retrieval.

**Second, version confusion.** Mainstream model families (e.g., GPT, Claude, DeepSeek, Qwen) iterate frequently, with multiple variants within a single family—preview versions, official releases, Plus/Max/Pro variants, etc. When comparing, LLMs frequently confuse versions—treating V3 data as V4, preview scores as official, or directly comparing scores across different modes. This version confusion causes comparison conclusions to be built on erroneous data foundations.

**Third, defaulting to legacy models as the strongest.** This is the most insidious and stubborn hallucination pattern in model comparison. Because GPT-4 era models were extensively discussed in training data, LLMs form a cognitive anchor that "these models are still top-tier." Even when these models have been surpassed by subsequent releases, the LLM still tends to use them as the "top" reference baseline, leading to systematic over- or under-estimation of new models' capabilities.

**Fourth, asymmetric retrieval.** When comparing two models, the LLM often retrieves information about only one while relying on training memory for the other. This asymmetry causes comparisons to be built on asymmetric information foundations—the retrieved model has current data, the unretrieved model uses outdated memory, and the comparison conclusion is naturally distorted.

**Fifth, bottom-tier magnetism and dimension-average inflation.** When a model is not in known rankings, the LLM tends to "magnetize" it to the bottom tier of known rankings rather than acknowledging it may be far below. Simultaneously, when a model is strong in one dimension and weak in another, the LLM tends to average them, thereby inflating the overall estimate—even when the weak dimension (especially code ability) is the more reliable signal of true intelligence.

These five challenges make model comparison a "perfect storm" for anti-hallucination—each challenge alone can distort conclusions, and when they cascade, the error magnitude can be amplified 3–4 times.

### 1.3 Contributions

This paper's contributions include: (1) systematic identification of five typical hallucination patterns in model comparison tasks; (2) design of specific countermeasures for each pattern, forming eight key innovations; (3) documentation of the iterative prompt engineering methodology—failure-node-analysis-driven improvement and anti-overfitting principles; (4) organization of the above mechanisms into a three-tier collaborative anti-inflation system, with cascading protection and redundancy for robustness; (5) open-sourcing of all prompts and methodology to provide a reproducible reference implementation for the community.

---

## 2. Background: Classification of Hallucination Patterns in Model Comparison

This chapter details five typical hallucination patterns in model comparison tasks. These patterns are not exhaustive but cover the main failure types observed in practice.

### 2.1 Training-Data Lag and Version Confusion

Large models have a clear training data cutoff. Taking August 2026 as an example, a model with a training cutoff in March 2026 knows nothing about models released or updated after April. However, when answering, the LLM often does not acknowledge this ignorance but instead "fills in" with stale knowledge from training memory—treating previous-generation data as current, or misattributing data from other models in the same family.

Version confusion is a derivative of training-data lag. Mainstream model families iterate frequently, with multiple versions and variants within a single family. For example, a model family may have V3, V3.5, V4, V4-Flash, V4-Pro, and other versions, each potentially with preview and official releases. When comparing, the LLM frequently confuses these versions—citing V3 scores to compare against V4, citing preview scores to compare against official, or directly comparing scores across different modes.

This version confusion causes comparison conclusions to be built on erroneous data foundations. For example, Model A's score on LiveCodeBench V5 might be directly compared against Model B's score on V6, even though V5 and V6 may have completely different difficulty levels, making the scores incomparable.

### 2.2 Cognitive Anchoring: Defaulting to Legacy Models as the Strongest

This is the most insidious and stubborn hallucination pattern in model comparison. GPT-4 era models were extensively discussed in training data, forming a cognitive anchor that "these models are top-tier." Even when these models have been comprehensively surpassed by subsequent models (e.g., Claude 3.5, GPT-5, DeepSeek V3), the LLM still tends to use them as the "top" reference baseline.

This cognitive anchoring leads to two types of errors: first, systematic over-estimation of new models—when a new model approaches GPT-4 on some dimension, the LLM tends to consider the new model "near top-tier," when in fact GPT-4 is no longer top-tier; second, systematic under-estimation—when a new model surpasses GPT-4 on some dimension, the LLM may underestimate the new model due to the prior that "it's impossible to surpass GPT-4."

More seriously, this cognitive anchoring cascades. Once a model is incorrectly benchmarked against GPT-4, subsequent comparisons may use this incorrect benchmark as a baseline, forming a "benchmarking chain" of systematic bias.

### 2.3 Asymmetric Retrieval

When comparing two models, the LLM often retrieves information about only one while relying on training memory for the other. This asymmetric retrieval is the most fundamental failure mode in comparison-type problems—the retrieved model has the latest, most complete data, while the unretrieved model uses outdated, incomplete memory, and the comparison conclusion is naturally built on an asymmetric foundation.

Typical manifestations of asymmetric retrieval include: retrieving only Model A's official Model Card while relying on training memory for Model B's outdated specifications; retrieving only Model A's latest benchmark scores while using previous-generation scores as substitutes for Model B; retrieving only Model A's current pricing while using outdated pricing for Model B. This asymmetry causes comparison conclusions to systematically favor the retrieved model.

More insidiously, the LLM is often unaware of this asymmetry—it believes it has "knowledge" of both models, just that one comes from retrieval and the other from memory. But in reality, the knowledge from memory may be severely outdated and incomparable to the latest retrieved data.

### 2.4 Bottom-Tier Magnetism Bias

When a model is not in known rankings, the LLM tends to "magnetize" it to the bottom tier of known rankings rather than acknowledging it may be far below. This "bottom-tier magnetism" bias is the most dangerous source of systematic over-estimation in comparison-type problems.

The root of bottom-tier magnetism lies in: known rankings (e.g., the knowledge base) typically include only head models; the bottom tier of the ranking is still the top of the entire model ecosystem, not the floor. But the LLM does not understand this—it sees "the lowest index in the ranking is 33" and anchors the estimation of non-ranked models to the 33–40 range, even though such models may be far below 33.

A typical manifestation: Model A is not in the knowledge base, with only one dimension's score approaching the bottom of the knowledge base, and the LLM claims "Model A is equivalent to Model X in the bottom tier of the knowledge base (index 40)"—this is systematic over-estimation. In reality, the knowledge base explicitly states that "the remaining hundreds of models may be far below the third tier level"; statistically, non-knowledge-base models are more likely to be far below the knowledge base bottom than near it.

### 2.5 Dimension-Average Inflation Bias

When a model is strong in one dimension and weak in another, the LLM tends to average them, thereby inflating the overall estimate. This "dimension-average inflation" bias is particularly dangerous in the 2026 model ecosystem, because capabilities in math, text generation, and other dimensions have become highly commoditized with greatly reduced discrimination, while code ability is the more reliable proxy for true intelligence.

A typical manifestation: Model A's math ability approaches Model B's, but its code ability is significantly weaker (e.g., a 10+ percentage point gap on SWE-bench), yet the LLM averages them and claims "the two have comparable overall capability." This is systematic over-estimation—strong math ability cannot compensate for weak code ability, because weak code ability typically means the model relies on pattern matching rather than true understanding.

In 2026, math/text capabilities are no longer scarce; code ability is the true intelligence watershed. SWE-bench Verified tests real-world bug fixing in real repositories, requiring understanding of complex codebases, multi-step reasoning, debugging, and system design—impossible to game through pattern matching. Math benchmarks (e.g., AIME) are susceptible to training data contamination and pattern matching; high scores do not represent true reasoning ability.

### 2.6 Cascading Effects of Hallucination Patterns

The above five hallucination patterns do not occur in isolation but frequently cascade. A typical failure reasoning chain might be: training-data lag leading to version confusion (Pattern 1+2) → asymmetric retrieval (Pattern 3) → bottom-tier magnetism (Pattern 4) → dimension-average inflation (Pattern 5), with the final conclusion's error magnitude amplified 3–4 times.

Each individual error may cause only 5–10% deviation, but after multiple errors cascade, the final conclusion may be completely inaccurate. For example, a model whose actual capability is far below the knowledge base bottom might, after the cascading amplification of five hallucination patterns, be incorrectly claimed as "equivalent to the bottom tier of the knowledge base." This cascading effect is the most dangerous characteristic of comparison-type problems—it means that a single anti-hallucination mechanism is insufficient to guarantee correct conclusions; a full-pipeline anti-inflation system must be constructed.

---

## 3. System Architecture

### 3.1 Overall Design: Retrieval-Augmented Reasoning System

Guncat Eval-LLM is fundamentally a Retrieval-Augmented Reasoning System. Its reasoning process is divided into seven stages: question understanding and requirement analysis, retrieval planning, tool invocation and source acquisition, source filtering and weight allocation, multi-source cross-validation, reasoning chain construction, and structured output.

Unlike traditional RAG systems, Guncat Eval-LLM's retrieval is not simple "retrieve-generate" but a closed loop of "retrieve-verify-reason-self-check." After retrieval, the system must perform source quality checks, cross-validation, and opposing hypothesis testing; after reasoning, it must execute a self-check list, ensuring every conclusion undergoes multiple verifications.

The system's core design principle is "uncertainty declaration takes priority over fabrication"—when information is insufficient, data is contradictory, or cross-validation is impossible, the system would rather explicitly answer "Based on currently available authoritative information, it is not yet possible to draw a conclusion" than fabricate an answer based on stale knowledge or low-quality sources. This principle is the baseline guarantee for anti-hallucination.

### 3.2 The 12-Step Workflow

The system employs a 12-step workflow, each step with clear inputs, outputs, and checkpoints:

1. **Current Date Confirmation and Requirement Clarification**: Confirm the real date, clarify user requirement dimensions
2. **Targeted Retrieval, Source Grading, and Filtering**: Execute symmetric retrieval, pre-citation source check gate
3. **Low-Information-Density Model Anchoring and Acceptance Principle**: Handle asymmetric priors for non-knowledge-base models
4. **Timeliness Verification and Version Management**: Version timestamp verification, mandatory benchmark version binding
5. **Model Generation Confirmation and Correction**: Generation classification, knowledge base benchmarking constraints
6. **Capability Dimension Decomposition**: Code ability as core proxy metric, gap quantification and generation-gap detection
7. **Scenario-Based Selection and Dynamic Head Cluster Identification**: Dynamically identify current-generation head models
8. **Equal Evaluation Principle for Domestic Models**: Correct the outdated perception that "domestic models are weaker than overseas models by default"
9. **Multi-Dimensional Cross-Validation**: Negative signal protection, opposing hypothesis testing
10. **Uncertainty Declaration and Risk Notification**: Explicitly declare data gaps and risks
11. **Self-Check List Execution**: Comparison-type problem-specific self-check (11 items)
12. **Structured Output**: Time baseline declaration, confidence labeling, timeliness notification

Among these, Step 2 (retrieval and source grading), Step 5 (knowledge base and benchmarking constraints), Step 6 (capability dimension decomposition and gap quantification), and Step 11 (self-check list) are the core anti-hallucination links, carrying the eight key mechanisms detailed in Chapter 5.

### 3.3 Source Grading System

The system employs a six-tier source grading system (Tier 1–6 / P0–P5), ensuring that source credibility is quantifiable and traceable. Lower-priority information must be overridden by higher-priority information, and key conclusions must be cross-validated in at least two independent authoritative sources.

| Source Tier | Source Type | Credibility | Use Case |
|-------------|-------------|-------------|----------|
| Tier 1 / P0 | Official technical reports, official Model Cards, official API documentation | Highest | Core specifications, official self-test data |
| Tier 2 / P1 | Authoritative evaluation institutions (Artificial Analysis, LMArena, SWE-bench official) | High | Benchmark scores, rankings |
| Tier 3 / P2 | Mainstream tech media (with editorial review, bylined journalists) | Medium-High | Industry dynamics, release coverage |
| Tier 4 / P3 | Community testing, user feedback, technical discussions | Medium (to be verified) | Risk alerts, reverse validation |
| Tier 5 / P4 | Unbylined self-media, AI-generated content, marketing accounts | Low | Leads only; independent use prohibited |
| Tier 6 / P5 | Anonymous forums, unsourced reposts | Very Low | Discard |

The key innovation of the source grading system is the "pre-citation mandatory check gate"—before citing any webpage or article as a source, six checks must be performed item by item: author and date, original link, AI-generated text features, domain reputation, data traceability. Sources that fail the check are prohibited from being used as independent evidence and may only serve as leads to guide further retrieval of original sources. This mechanism effectively filters data contamination from low-quality sources.

### 3.4 Knowledge Base and Timeliness Anchor

The system has a built-in time-anchored knowledge base that records the tier landscape of the world's mainstream models as of a specific date. The knowledge base's role is not to provide precise version-level data but to set a baseline constraint on information timeliness—the actual referenced information's freshness must not fall below this knowledge base level.

Key characteristics of the knowledge base include: it provides only macro-level tier division at the model family level, prohibiting reference to precise rankings of specific sub-versions; it has an explicit timeliness hard constraint (e.g., "if the current time has exceeded the anchor by more than 3 months, the tier division in the knowledge base will be completely invalid"); the capability distribution of models within the same release period exhibits an extreme long tail, and the knowledge base includes only the top 90% of attention-worthy models.

The knowledge base's tier division uses an Intelligence Index as a quantitative metric, categorizing models into Tier 1 (index 55–61), Tier 2 (index 50–54), Tier 3 (index 40–46), etc. This index system provides a quantitative foundation for benchmarking constraints—when the system claims "Model A is equivalent to Model B," it must be based on intelligence index gap verification; if the gap exceeds 5, the "equivalent" expression is prohibited.

---

## 4. Prompt Engineering Methodology

### 4.1 Iterative Improvement Process

Guncat Eval-LLM's prompt engineering employs an iterative methodology of "failure-node-analysis-driven improvement." The core philosophy of this methodology is: prompt improvements should not be based on intuition or general best practices, but on layer-by-layer decomposition of specific failure reasoning chains—identifying the erroneous input, erroneous reasoning, and erroneous output at each decision point, then designing specific check mechanisms for each failure node.

The system's prompt underwent three main rounds of iteration, each targeting a class of systematic bias: the first round targeted information asymmetry and source quality lapses, designing mechanisms such as symmetric retrieval rules, pre-citation source check gates, gap quantification, and generation-gap detection; the second round targeted bottom-tier magnetism bias, designing asymmetric priors and bottom-tier magnetism prohibitions; the third round targeted dimension-average inflation bias, designing code-ability-as-core-proxy weighting rules.

The advantage of this iterative methodology is that each improvement corresponds to a clear failure pattern, avoiding the blindness of "improving for improvement's sake." Simultaneously, failure-node analysis ensures the targeted nature of improvements—each mechanism solves a specific, reproducible reasoning defect rather than vaguely "improving quality."

### 4.2 Failure-Node-Analysis-Driven Improvement

The core of failure-node analysis is to decompose a failed reasoning chain into multiple decision points, then perform a tripartite analysis of "erroneous input—erroneous reasoning—erroneous output" for each decision point. Taking a model comparison task as an example, a typical failure reasoning chain can be decomposed into the following nodes:

- **Retrieval planning stage**: Failed to symmetrically retrieve the benchmarked model's specifications, relying on training memory instead
- **Source acquisition stage**: Obtained erroneous data from low-quality self-media, failed to perform source quality checks
- **Source weight allocation stage**: Gave excessive weight to low-quality sources, community feedback downgraded and ignored
- **Data interpretation stage**: Gap severely underestimated, anchoring bias led to "roughly equivalent" misjudgment
- **Cross-validation stage**: Selectively cited supporting evidence, ignored counter-evidence (confirmation bias)
- **Conclusion construction stage**: Used ecological positioning to obscure capability gaps
- **Knowledge base reference stage**: Failed to use knowledge base to constrain conclusions, benchmarking model index gap exceeded limits

Each failure node corresponds to a specific improvement mechanism. For example, "asymmetric retrieval" in the retrieval planning stage corresponds to the "symmetric retrieval rule"; "unrecognized low-quality sources" in the source acquisition stage corresponds to the "pre-citation source check gate"; "gap underestimation" in the data interpretation stage corresponds to "gap quantification and rank mapping." This one-to-one correspondence makes improvements traceable and verifiable.

### 4.3 Anti-Overfitting Principles

During prompt iteration, a key risk is overfitting—hardcoding the specific conclusions of the validation set into the prompt rather than extracting general rules. For example, if the validation set shows "Model A was over-estimated," the wrong improvement would be to write "Model A has limited capability" into the prompt; the correct improvement is to extract the general rule "models not in the knowledge base default to below the knowledge base bottom tier."

The system employs three anti-overfitting principles:

- **Generic placeholder principle**: All rules use generic placeholders like "Model A" and "Model B," without referencing specific model names from the validation set. After improvement, verification confirms that no validation set model names appear in the new rules.
- **Failure pattern abstraction principle**: Specific errors from the validation set (e.g., "a 10.5 percentage point gap described as roughly equivalent") are abstracted into general rules ("gaps must be quantified as rank positions; vague expressions are prohibited"), applicable to any model comparison scenario.
- **Rule generalizability principle**: Each rule must hold for any model comparison, not just for validation set cases. For example, the "generation-gap detection" rule—"if Model A's score is lower than Model B's predecessor version, claiming equivalence to Model B is prohibited"—holds for any model family comparison.

The anti-overfitting principle ensures the prompt's generalization capability—the improved prompt can correctly handle not only the validation set cases but also any similar model comparison task. This is the essential difference between "memorizing answers" and "understanding rules."

---

## 5. Key Innovation Mechanisms

This chapter details the eight key anti-hallucination mechanisms formed through three rounds of iteration. These mechanisms cover three layers—information acquisition, benchmark anchoring, and intelligence estimation—forming a collaborative anti-inflation system.

### 5.1 Symmetric Retrieval Rule

The symmetric retrieval rule is designed to counter asymmetric retrieval bias (Pattern 3). When a user question involves comparison, benchmarking, or equivalence judgment of two or more models, the system must independently retrieve a complete specification list for each model, prohibiting the use of training memory as a substitute for any item.

The symmetric retrieval list includes six dimensions: context window length, key benchmark scores (with version numbers and dates), API pricing, open-source license, release time and version status, and intelligence index. If, after symmetric retrieval, any model has missing data on any dimension, the system must explicitly note in the output "[Model name]'s [dimension] data is missing; this dimension's comparison is incomplete," prohibiting "filling in" with the other model's data or "patching" with training memory.

The key innovation of the symmetric retrieval rule is "symmetry self-check"—generating two parallel retrieval lists during the retrieval planning stage and checking item by item whether both sides have been retrieved. If an item is found to have been retrieved for only one side, the system must either retrieve the other side or declare the dimension's comparison incomplete in the output. This self-check mechanism effectively prevents the hidden bias of information asymmetry.

### 5.2 Pre-Citation Mandatory Source Check Gate

The pre-citation mandatory source check gate is designed to counter source quality lapses. Before citing any webpage or article as a source, the system must perform six checks item by item; those that fail are prohibited from being used as independent evidence.

| Check Item | Check Content | Failure Handling |
|------------|---------------|------------------|
| Author and date | Whether there is a clear author byline and publication date | No: downgrade or discard |
| Original link | Whether a link to the original data source is provided | No: downgrade |
| AI-generated features | Whether it matches templated openings, empty adjective stacking | Yes: flag as suspicious, downgrade |
| Domain reputation | Whether it comes from a known low-quality domain | Yes: discard |
| Data traceability | Whether benchmark scores can be found in the original leaderboard | No: treat as hallucination, discard |
| Cross-validation | Whether it contradicts Tier 1–2 sources | Contradiction: defer to higher priority |

The innovation of this mechanism lies in transforming source quality checking from "post-identification processing" to "pre-citation mandatory gating." Identification itself relies on active attention and is easily missed; mandatory gating ensures every citation is checked, and those that fail cannot enter the reasoning chain. The check process must be explicitly recorded in the internal reasoning chain for self-check list review.

### 5.3 Asymmetric Prior and Bottom-Tier Magnetism Prohibition

The asymmetric prior and bottom-tier magnetism prohibition are designed to counter bottom-tier magnetism bias (Pattern 4). This is one of the system's most critical innovations, solving the problem of systematic over-estimation of non-knowledge-base models.

The core cognition of the asymmetric prior is: the knowledge base includes only head models (approximately 90% of evaluation attention), not the complete distribution of model capabilities. The bottom tier of the knowledge base is the top of the entire model ecosystem, not the floor. Therefore, for models not in the knowledge base ranking, the system executes an asymmetric prior—defaulting to their capability being below the knowledge base bottom tier, rather than "approaching the knowledge base bottom" or "within some knowledge base tier."

To overturn the default assumption of "below the knowledge base bottom," multi-dimensional strong evidence must be provided—that is, on at least 3 independent benchmarks, the model's scores must reach or exceed the scores of models in the knowledge base bottom tier. A single dimension's advantage (e.g., a high ranking on one benchmark) is insufficient to overturn the default assumption, because a single-dimension advantage may represent a specialty rather than overall capability.

The bottom-tier magnetism prohibition is the execution rule for the asymmetric prior. The system prohibits defaulting non-knowledge-base models to knowledge base bottom-tier models—not "because no lower reference can be found, benchmark against the lowest." If the estimated index is below the knowledge base bottom, the system must declare "this model's capability is below all head models included in the knowledge base; no precise benchmark can be found in the knowledge base," rather than forcing a benchmark within the knowledge base.

### 5.4 Code Ability as the Core Proxy Metric for General Intelligence

The weighting rule for code ability as the core proxy metric for general intelligence is designed to counter dimension-average inflation bias (Pattern 5). This mechanism is based on in-depth observation of the 2026 model ecosystem: capabilities in math, text generation, instruction following, and other dimensions have become highly commoditized; the vast majority of models have reached a "good enough" level on these dimensions, and discrimination has greatly decreased. Code ability has become the most reliable and least contamination-prone proxy metric for distinguishing true model intelligence.

Reasons for code ability as the core proxy metric include: SWE-bench Verified tests real-world bug fixing in real repositories, requiring understanding of complex codebases, multi-step reasoning, debugging, and system design—impossible to game through pattern matching; math benchmarks (e.g., AIME) are susceptible to training data contamination and pattern matching; high scores do not represent true reasoning ability; text and creative writing are subjective, and surface fluency easily masks underlying reasoning defects; code results are objective—tests either pass or fail, with no ambiguity.

Based on this cognition, the system executes code-ability weighting rules when estimating general intelligence: code ability holds the primary weight (suggested ≥50%); weak code ability cannot be compensated by other dimensions—if a model's code ability is significantly weaker than other dimensions, the general intelligence estimate should gravitate toward the code ability level rather than taking the average across dimensions; "dimension-average inflation" is prohibited—simple averaging of strong and weak dimensions to inflate the overall estimate is forbidden; code generation gap takes priority—when code ability and other dimensions show a generation gap, the code ability generation gap governs the general intelligence level judgment.

### 5.5 Gap Quantification and Generation-Gap Detection

Gap quantification and generation-gap detection are designed to counter gap quantification distortion. The system prohibits using only vague expressions like "roughly equivalent," "close," or "small gap"; it must execute a quantification process.

The gap quantification rule includes four steps: calculate the absolute gap (e.g., 10.5 percentage points); map the score difference to rank density (how many rank positions correspond to each percentage point); introduce the benchmarked model's predecessor version as a reference baseline; express using rank gap rather than just score gap. For example, "a 10.5 percentage point gap, corresponding to approximately 20–30 rank positions" provides quantifiable, verifiable information compared to "a small gap."

Generation-gap detection is an extension of gap quantification. If Model A's score on a benchmark is lower than Model B's predecessor version (i.e., Model A < Model B predecessor < Model B current), a "generation gap" warning is triggered—claiming "Model A is equivalent to Model B" is prohibited; the system must declare "Model A's capability is lower than Model B's predecessor version, and therefore significantly weaker than Model B's current version." This mechanism effectively prevents the over-estimation of "worse than the predecessor yet claimed as equivalent to the current generation."

### 5.6 Opposing Hypothesis Testing

Opposing hypothesis testing is designed to counter confirmation bias. Confirmation bias is the most common reasoning defect in model evaluation—forming a preliminary judgment first, then selectively citing supporting evidence. To counter this bias, after forming a preliminary conclusion of "Model A is equivalent to/superior to/inferior to Model B," the system must explicitly perform opposing hypothesis testing.

The opposing hypothesis testing process includes four steps: generate the opposing hypothesis (if the preliminary conclusion is "Model A ≈ Model B," the opposing hypothesis is "Model A is significantly weaker or stronger than Model B"); actively retrieve counter-evidence (actively retrieve benchmark data, rank positions, community feedback, and third-party evaluations supporting the opposing hypothesis); evidence symmetry assessment (compare the quantity and quality of evidence supporting the preliminary conclusion vs. the opposing hypothesis); judgment (if the opposing hypothesis's evidence is more substantial or evenly matched, the preliminary conclusion must be overturned or revised).

The key innovation of opposing hypothesis testing is "explicitization"—transforming the otherwise implicit confirmation bias into an explicit, checkable step. The system prohibits outputting "equivalent/superior/inferior" conclusions without performing opposing hypothesis testing, ensuring every benchmarking conclusion undergoes counter-evidence examination.

### 5.7 Question Type Classifier

The question type classifier is designed to counter the bias of capability benchmarking being diluted by ecological positioning discourse. Before retrieval planning, the system must identify the user's question type and select different analysis frameworks and output templates accordingly. Incorrect question type identification will cause the entire reasoning chain to deviate.

| Question Type | Identification Features | Output Requirements |
|---------------|--------------------------|---------------------|
| Pure capability benchmarking | "Equivalent to what model" "How does it compare to XX" | Prohibit mixing in ecological positioning, price, strategic value, and other non-capability factors |
| Selection recommendation | "Which should I choose" "What do you recommend" | Comprehensive capability + ecological positioning + price + deployment conditions |
| Comprehensive evaluation | "How is XX model" "Evaluate XX" | Capability + ecological positioning + pros/cons + applicable scenarios |
| Existence query | "What is XX model" "Is XX still around" | Prioritize existence determination and version verification |

The key rule of the question type classifier is: when the user's question is "pure capability benchmarking," using ecological positioning value, strategic significance, domestic substitution, autonomous controllability, and other non-capability discourse to dilute or obscure capability gaps is prohibited. Capability benchmarking conclusions must be independently derived from benchmark data; ecological positioning analysis (if necessary) must be presented as a separate section, clearly separated from capability conclusions, and must not be mixed in the same conclusion paragraph.

### 5.8 Knowledge Base Benchmarking Constraints

Knowledge base benchmarking constraints are designed to counter knowledge base constraint failure. When a user asks "What model is Model A equivalent to?", the knowledge base is not only a timeliness reference but also a hard constraint on benchmarking conclusions. The system must execute a four-step process: determine whether Model A is in the knowledge base ranking; estimate Model A's intelligence index (if not in the ranking); benchmark candidate selection and gap verification; knowledge base constraints on benchmarking conclusions.

The core rule of knowledge base benchmarking constraints is intelligence index gap verification: if the gap exceeds 5 (approximately one tier spacing), the "equivalent" expression is prohibited and must be changed to "significantly lower than" or "significantly higher than"; if the gap is between 2–5, "slightly lower than/slightly higher than" must be used; if the gap does not exceed 2, "equivalent" may be used but confidence must be noted. This quantitative constraint effectively prevents the over-estimation of "a 7-point index gap described as equivalent."

Combined with the asymmetric prior (Section 5.3), the knowledge base benchmarking constraint also includes a "bottom-tier magnetism" prohibition: if the estimated index is below the knowledge base bottom (e.g., below 33), searching for benchmark candidates within the knowledge base is prohibited; the system must declare "this model's capability is below all head models included in the knowledge base; no precise benchmark can be found in the knowledge base." This rule ensures that non-knowledge-base models are not forcibly magnetized to the knowledge base bottom.

---

## 6. Three-Tier Collaborative Anti-Inflation System

The above eight mechanisms do not operate in isolation but form a collaborative anti-inflation system across three layers: information acquisition, benchmark anchoring, and intelligence estimation. This chapter explains how these three tiers collaboratively and systematically counter the five hallucination patterns.

### 6.1 Information Acquisition Layer

The information acquisition layer is the first line of defense in the anti-inflation system, corresponding to Step 2 (retrieval and source grading) of the workflow. This layer contains two core mechanisms: the symmetric retrieval rule (5.1) and the pre-citation mandatory source check gate (5.2).

The symmetric retrieval rule ensures that both compared models receive equally deep, current data, preventing asymmetric retrieval bias (Pattern 3). The pre-citation mandatory source check gate ensures that every citation undergoes quality verification, preventing data contamination from low-quality sources. The two mechanisms collaborate to ensure from the source that the reasoning chain is built on a symmetric, high-quality information foundation.

The output of the information acquisition layer is a "verified symmetric information set"—complete specification lists for both models, with each data point annotated with source, date, and confidence. This information set forms the foundation for benchmark anchoring and intelligence estimation.

### 6.2 Benchmark Anchoring Layer

The benchmark anchoring layer is the second line of defense in the anti-inflation system, corresponding to Step 5 (knowledge base and benchmarking constraints) of the workflow. This layer contains three core mechanisms: the asymmetric prior and bottom-tier magnetism prohibition (5.3), knowledge base benchmarking constraints (5.8), and the question type classifier (5.7).

The asymmetric prior ensures that non-knowledge-base models default to below the knowledge base bottom, preventing bottom-tier magnetism bias (Pattern 4). Knowledge base benchmarking constraints, through intelligence index gap verification, prevent the over-estimation of "large index gap described as equivalent." The question type classifier ensures that pure capability benchmarking questions are not diluted by ecological positioning discourse, preventing capability conclusions from being obscured by non-capability factors.

The output of the benchmark anchoring layer is a "constrained benchmarking conclusion"—either a quantified capability gap expression (e.g., "significantly lower, intelligence index gap approximately 7") or a declaration that "no precise benchmark can be found in the knowledge base." This output provides the positioning foundation for intelligence estimation.

### 6.3 Intelligence Estimation Layer

The intelligence estimation layer is the third line of defense in the anti-inflation system, corresponding to Step 6 (capability dimension decomposition and gap quantification) of the workflow. This layer contains three core mechanisms: code ability as the core proxy metric for general intelligence (5.4), gap quantification and generation-gap detection (5.5), and opposing hypothesis testing (5.6).

The code-ability weighting rule ensures that general intelligence estimation uses code ability as the primary weight, preventing dimension-average inflation bias (Pattern 5). Gap quantification and generation-gap detection ensure that capability gaps are quantified as rank positions rather than vague expressions and detect "worse than the predecessor" generation gaps. Opposing hypothesis testing ensures that every benchmarking conclusion undergoes counter-evidence examination, preventing confirmation bias.

The output of the intelligence estimation layer is a "counter-evidence-verified quantified estimate"—a general intelligence estimate anchored on code ability, having undergone opposing hypothesis testing, and quantified as rank positions. This output is the core content of the final structured output.

### 6.4 Cascading Protection of Three-Tier Collaboration

The three-tier collaborative anti-inflation system counters the five hallucination patterns through cascading protection. The information acquisition layer prevents Pattern 3 (asymmetric retrieval) and low-quality source contamination; the benchmark anchoring layer prevents Pattern 4 (bottom-tier magnetism) and knowledge base constraint failure; the intelligence estimation layer prevents Pattern 5 (dimension-average inflation) and confirmation bias. Pattern 1 (training-data lag) and Pattern 2 (defaulting to legacy models as strongest) are countered collaboratively across all three tiers—the information acquisition layer's symmetric retrieval prevents training memory substitution, the benchmark anchoring layer's knowledge base timeliness anchor prevents legacy model anchoring, and the intelligence estimation layer's code-ability weighting prevents interference from outdated dimensions.

The advantage of this cascading protection is redundancy—even if a mechanism in one tier fails, mechanisms in other tiers can still provide protection. For example, even if symmetric retrieval is not fully executed, the pre-citation source check gate can still filter low-quality sources; even if the bottom-tier magnetism prohibition is not triggered, the knowledge base benchmarking constraint's index gap verification can still prevent over-estimation. This redundancy makes the anti-inflation system robust.

---

## 7. Evaluation and Discussion

### 7.1 Failure Pattern Coverage Analysis

This section analyzes the coverage of the five hallucination patterns by the eight key mechanisms, evaluating the completeness of the anti-inflation system.

| Hallucination Pattern | Core Countermeasures | Coverage Layer | Coverage Strength |
|------------------------|---------------------|----------------|-------------------|
| Training-data lag and version confusion | Symmetric retrieval rule + knowledge base timeliness anchor | Information acquisition + benchmark anchoring | Strong |
| Defaulting to legacy models as strongest | Knowledge base timeliness anchor + code-ability weighting | Benchmark anchoring + intelligence estimation | Strong |
| Asymmetric retrieval | Symmetric retrieval rule | Information acquisition | Strong |
| Bottom-tier magnetism bias | Asymmetric prior + bottom-tier magnetism prohibition | Benchmark anchoring | Strong |
| Dimension-average inflation bias | Code-ability weighting + gap quantification | Intelligence estimation | Strong |

The coverage analysis shows that all five hallucination patterns are strongly covered by at least one core mechanism, and most patterns are countered collaboratively by multi-layer mechanisms. This indicates that the anti-inflation system has completeness in failure pattern coverage.

### 7.2 Limitations

Although the anti-inflation system covers the five identified hallucination patterns, several limitations remain, requiring continuous improvement in future work.

**First, knowledge base timeliness constraints.** The knowledge base has an explicit timeliness hard constraint (e.g., "if the current time has exceeded the anchor by more than 3 months, the tier division in the knowledge base will be completely invalid"). This means the system needs to periodically update the knowledge base, or the foundation of the anti-inflation system will fail. In the rapidly iterating model ecosystem, a 3-month update cycle may still be too long.

**Second, subjectivity of code-ability weighting.** The threshold of code ability holding primary weight (suggested ≥50%) is based on observation of the 2026 model ecosystem but lacks rigorous quantitative validation. As the model ecosystem evolves, this weight may need adjustment—for example, if Agent capability becomes a more reliable intelligence proxy metric in the future, weight allocation may need rebalancing.

**Third, execution cost of opposing hypothesis testing.** Opposing hypothesis testing requires the system to actively retrieve counter-evidence after forming a preliminary conclusion. This process increases reasoning time and tool invocation costs. In resource-constrained scenarios, trade-offs between thoroughness and efficiency may be necessary.

**Fourth, boundaries of anti-overfitting.** The anti-overfitting principle ensures that rules do not hardcode validation set conclusions, but it also introduces a risk: general rules may not cover certain special failure patterns. For example, if a class of models has a unique over-estimation pattern, general rules may not precisely capture it. This requires continuous balancing between generalizability and precision.

### 7.3 Future Work

Based on the above limitations, future work can proceed in the following directions:

- **Knowledge base auto-update mechanism**: Research how to achieve dynamic knowledge base updates through automated retrieval and leaderboard monitoring, shortening the timeliness constraint window.
- **Weight adaptation**: Research how to automatically adjust the weight of code ability in general intelligence estimation based on model ecosystem evolution, rather than fixed thresholds.
- **Efficiency optimization of opposing hypothesis testing**: Research how to reduce the execution cost of opposing hypothesis testing while ensuring the thoroughness of counter-evidence examination.
- **Identification of more hallucination patterns**: Through larger-scale failure case analysis, identify hallucination patterns beyond the current five, expanding the anti-inflation system's coverage.
- **Cross-lingual model evaluation**: The current system primarily targets the Chinese-English model ecosystem; future work can extend to more languages and regional model evaluation scenarios.

---

## 8. Conclusion

This paper introduced the design and prompt engineering of the open-source large model evaluation intelligence analyst agent Guncat Eval-LLM. Targeting model comparison as the quintessential anti-hallucination proposition, the agent employs a 12-step workflow and eight key mechanisms to construct a three-tier anti-inflation system covering information acquisition, benchmark anchoring, and intelligence estimation.

The core contribution of this paper lies in the systematic identification of five typical hallucination patterns in model comparison tasks—training-data lag and version confusion, cognitive anchoring defaulting to legacy models as strongest, asymmetric retrieval, bottom-tier magnetism bias, and dimension-average inflation bias—and the design of specific countermeasures for each pattern. These mechanisms, through cascading protection and redundancy design, form a robust anti-inflation system.

This paper also documented in detail the iterative prompt engineering methodology—failure-node-analysis-driven improvement and anti-overfitting principles. This methodology ensures that each improvement corresponds to a clear failure pattern and that improvement rules generalize to any model comparison scenario rather than overfitting to specific validation set conclusions. This methodology has reference value for anti-hallucination research in the large model evaluation field.

Guncat Eval-LLM and its prompt engineering methodology are open-sourced to provide the community with a reproducible anti-hallucination reference implementation. We hope this work will promote systematic research on hallucination patterns in the large model evaluation field and the engineering practice of anti-hallucination mechanisms. In the future of rapid model iteration, reliable model comparison intelligence will become the infrastructure for technical decision-making, and anti-hallucination capability is the core guarantee of this infrastructure.

---

## References

[1] OpenAI. GPT-4 Technical Report. arXiv:2303.08774, 2023.

[2] Anthropic. Claude 3 Model Card. Anthropic Official Documentation, 2024.

[3] DeepSeek-AI. DeepSeek-V3 Technical Report. arXiv:2412.19437, 2024.

[4] Jimenez C E, Yang J, Wettig S, et al. SWE-bench: Can Language Models Resolve Real-World GitHub Issues? ICLR 2024.

[5] Hendrycks D, Burns C, Basart S, et al. Measuring Massive Multitask Language Understanding. ICLR 2021.

[6] Rein D, Hou B L, Stickland A C, et al. GPQA: A Graduate-Level Google-Proof Q&A Benchmark. arXiv:2311.12022, 2023.

[7] Artifex Software. Artificial Analysis Intelligence Index. https://artificialanalysis.ai/, 2026.

[8] LMArena. Chatbot Arena Leaderboard. https://lmarena.ai/, 2026.

[9] Lewis P, Perez E, Piktus A, et al. Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks. NeurIPS 2020.

[10] Wei J, Wang X, Schuurmans D, et al. Chain-of-Thought Prompting Elicits Reasoning in Large Language Models. NeurIPS 2022.

[11] Tversky A, Kahneman D. Judgment under Uncertainty: Heuristics and Biases. Science, 1974, 185(4157): 1124-1131.

[12] Wason P C. On the Failure to Eliminate Hypotheses in a Conceptual Task. Quarterly Journal of Experimental Psychology, 1960, 12(3): 129-140.

[13] Brown T B, Mann B, Ryder N, et al. Language Models are Few-Shot Learners. NeurIPS 2020.

[14] Touvron H, Lavril T, Izacard G, et al. LLaMA: Open and Efficient Foundation Language Models. arXiv:2302.13971, 2023.

[15] Bai J, Bai S, Chu Y, et al. Qwen Technical Report. arXiv:2309.16609, 2023.

[16] Wei J, Tay Y, Bommasani R, et al. Emergent Abilities of Large Language Models. TMLR 2022.

[17] Lin S, Hilton J, Evans O. TruthfulQA: Measuring How Models Mimic Human Falsehoods. ACL 2022.

[18] EvalPlus. EvalPlus: A Framework for Evaluating Code Generation. https://evalplus.github.io/, 2024.

[19] LiveBench. LiveBench: A Challenging, Contamination-Limited LLM Benchmark. https://livebench.ai/, 2026.

[20] OpenCompass. OpenCompass: A Universal Evaluation Platform for Foundation Models. https://opencompass.org.cn/, 2026.

---

*This paper and the Guncat Eval-LLM agent prompt are open-sourced. Community contributions and improvements are welcome.*
