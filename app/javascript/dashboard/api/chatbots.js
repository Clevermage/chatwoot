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

  update(id, data) {
    return axios.patch(`${this.url}/${id}/`, data, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  updateDocuments(id, data) {
    return axios.patch(`${this.url}/${id}/process_file`, data, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  deleteFile(id, fileId) {
    return axios.delete(`${this.url}/${id}/destroy_file/`, {
      params: { file_id: fileId.file_id },
    });
  }
}

export default new ChatbotAPI();
