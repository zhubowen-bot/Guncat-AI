// 智能体(对齐 web 版本的 agents.json 中的 agent)
export class Agent {
  id: string = '';
  name: string = '';
  description: string = '';
  category: string = '';
  promptFile: string = '';
  systemPrompt: string = '';

  static of(id: string, name: string, description: string, category: string,
    promptFile: string, systemPrompt: string): Agent {
    let agent: Agent = new Agent();
    agent.id = id;
    agent.name = name;
    agent.description = description;
    agent.category = category;
    agent.promptFile = promptFile;
    agent.systemPrompt = systemPrompt;
    return agent;
  }
}
