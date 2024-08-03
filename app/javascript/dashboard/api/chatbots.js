/* global axios */
import ApiClient from './ApiClient';

export const buildContactParams = (page, sortAttr, label, search) => {
  let params = `include_contact_inboxes=false&page=${page}&sort=${sortAttr}`;
  if (search) {
    params = `${params}&q=${search}`;
  }
  if (label) {
    params = `${params}&labels[]=${label}`;
  }
  return params;
};

class ChatbotAPI extends ApiClient {
  constructor() {
    super('chatbots', { accountScoped: true });
  }

  getConfig() {
    return axios.get(`${this.url}`);
  }
}

export default new ChatbotAPI();
