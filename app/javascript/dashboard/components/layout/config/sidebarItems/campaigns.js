import { frontendURL } from '../../../../helper/URLHelper';

const campaigns = accountId => ({
  parentNav: 'campaigns',
  routes: ['ongoing_campaigns', 'one_off', 'template_whatsapp'],
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'ONGOING',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
      toStateName: 'ongoing_campaigns',
    },
    {
      key: 'oneOffCampaigns',
      icon: 'sound-source',
      label: 'ONE_OFF',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
      toStateName: 'one_off',
    },
    {
      key: 'templateWhatsappCampaigns',
      icon: 'list',
      label: 'TEMPLATE_WHATSAPP',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/templates`),
      toStateName: 'template_whatsapp',
    },
  ],
});

export default campaigns;
