import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const SettingsWrapper = () => import('../SettingsWrapper.vue');
const Index = () => import('./Index.vue');
const KnoChatbot = () => import('./KnoChatbot');
const Intensions = () => import('./IntensionsChatbot');
const Integrations = () => import('./IntegrationChatbot');
const Functions = () => import('./Functions');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/chatbot'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsContent,
      props: {
        headerTitle: 'CHATBOT_SETTINGS.TITLE',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'setting',
        },
        {
          path: 'setting',
          name: 'setting_chatbot',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },

    {
      path: frontendURL('accounts/:accountId/chatbot'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CHATBOT_SETTINGS.TITLE',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'knowledge',
        },
        {
          path: 'knowledge',
          name: 'knowledge_base_chatbot',
          meta: {
            permissions: ['administrator'],
          },
          component: KnoChatbot,
        },
      ],
    },

    {
      path: frontendURL('accounts/:accountId/chatbot'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CHATBOT_SETTINGS.TITLE',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'intensions',
        },
        {
          path: 'intensions',
          name: 'intensions_chatbot',
          meta: {
            permissions: ['administrator'],
          },
          component: Intensions,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/chatbot'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CHATBOT_SETTINGS.TITLE',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'ecommerce',
        },
        {
          path: 'ecommerce',
          name: 'ecommerce_chatbot',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },

    {
      path: frontendURL('accounts/:accountId/chatbot'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CHATBOT_SETTINGS.TITLE',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'integrations',
        },
        {
          path: 'integrations',
          name: 'integrations_chatbot',
          meta: {
            permissions: ['administrator'],
          },
          component: Integrations,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/chatbot'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CHATBOT_SETTINGS.TITLE',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          redirect: 'functions',
        },
        {
          path: 'functions',
          name: 'functions_chatbot',
          meta: {
            permissions: ['administrator'],
          },
          component: Functions,
        },
      ],
    },
  ],
};
