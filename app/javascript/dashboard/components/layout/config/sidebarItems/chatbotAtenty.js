import { frontendURL } from '../../../../helper/URLHelper';

const chatbot = accountId => ({
  parentNav: 'chatbot',
  routes: [
    'setting_chatbot',
    'knowledge_base_chatbot',
    'intensions_chatbot',
    'ecommerce_chatbot',
    'integrations_chatbot',
    'functions_chatbot',
  ],
  menuItems: [
    {
      icon: 'settings',
      label: 'CHATBOT_SETTING',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/chatbot/setting`),
      toStateName: 'setting_chatbot',
    },
    {
      icon: 'upload',
      label: 'CHATBOT_KNOWLEDGE',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/chatbot/knowledge`),
      toStateName: 'knowledge_base_chatbot',
    },
    {
      icon: 'emoji',
      label: 'CHATBOT_INTENSIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/settings/automation/list`),
      toStateName: 'intensions_chatbot',
    },
    {
      icon: 'content-settings',
      label: 'CHATBOT_FUNCTIONS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/chatbot/functions`),
      toStateName: 'functions_chatbot',
    },
  ],
});

export default chatbot;
