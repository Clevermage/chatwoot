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

class ChatbotFunctionAPI extends ApiClient {
  constructor() {
    super('chatbot_functions', { accountScoped: true });
  }

  getFunctions() {
    return axios.get(`${this.url}`);
  }

  getChatbots() {
    return axios.get(`${this.url}/chatbots`);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}/`, data);
  }
}

export default new ChatbotFunctionAPI();
