import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ChatbotFunctionAPI from '../../api/chatbotFunctions';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getFunctions(_state) {
    return _state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContactLabels: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  get: async function getFunctions({ commit }) {
    commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isFetching: true });
    try {
      const response = await ChatbotFunctionAPI.getFunctions();
      commit(types.SET_CHAT_BOT_FUNCTIONS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isFetching: false });
    }
  },

  getChatbots: async function getChatbots({ commit }) {
    commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isFetching: true });
    try {
      const response = await ChatbotFunctionAPI.getChatbots();
      // commit(types.SET_CHAT_BOT_FUNCTIONS_CHATBOTS, response.data);
      return response.data;
    } catch (error) {
      return null;
    } finally {
      commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createFunction({ commit }, cannedObj) {
    commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isCreating: true });
    try {
      const response = await ChatbotFunctionAPI.create(cannedObj);
      commit(types.ADD_CHAT_BOT_FUNCTION, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isCreating: false });
    }
  },
  update: async function updateFunctions({ commit }, { id, ...updateObj }) {
    commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatbotFunctionAPI.update(id, updateObj);
      // AnalyticsHelper.track(LABEL_EVENTS.UPDATE);
      commit(types.EDIT_CHAT_BOT_FUNCTION, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteFunction({ commit }, id) {
    commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isDeleting: true });
    try {
      await ChatbotFunctionAPI.delete(id);
      commit(types.DELETE_CHAT_BOT_FUNCTION, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CHAT_BOT_FUNCTION_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_CHAT_BOT_FUNCTION_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_CHAT_BOT_FUNCTIONS]: MutationHelpers.set,
  [types.ADD_CHAT_BOT_FUNCTION]: MutationHelpers.create,
  [types.EDIT_CHAT_BOT_FUNCTION]: MutationHelpers.update,
  [types.DELETE_CHAT_BOT_FUNCTION]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
