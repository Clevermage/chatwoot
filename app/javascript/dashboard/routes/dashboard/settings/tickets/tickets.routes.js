import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/tickets'),
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
          name: 'setting_tickets',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
