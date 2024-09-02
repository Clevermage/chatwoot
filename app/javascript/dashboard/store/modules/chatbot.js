import Vue from 'vue';
import types from '../mutation-types';
import ChatbotAPI from '../../api/chatbots';
import { throwErrorMessage } from '../utils/api';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContactLabels: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  get: async () => {
    // commit(types.SET_CONTACT_LABELS_UI_FLAG, {
    //  isFetching: true,
    // });
    try {
      const response = await ChatbotAPI.getConfig();
      const resp = response.data[0];

      return resp;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    }
  },

  update: async ({ commit }, { id, ...chatBotObj }) => {
    commit(types.SET_CHAT_BOT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatbotAPI.update(id, chatBotObj);
      // return response.data;
      commit(types.EDIT_CHAT_BOT, response.data);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },
  deleteFile: async ({ commit }, { id, ...chatBotObj }) => {
    commit(types.SET_CHAT_BOT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatbotAPI.deleteFile(id, chatBotObj);
      // return response.data;
      commit(types.EDIT_CHAT_BOT, response.data);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_CHAT_BOT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_CHAT_BOT_UI_FLAG]: ($state, { id, data }) => {
    Vue.set($state.records, id, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
