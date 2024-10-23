<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getLabelTitleErrorMessage } from './validations';
import { useVuelidate } from '@vuelidate/core';

export default {
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      chatbot: '',
      chatbots: [],
      name: '',
      code_function: [],
      jsonString: '',
      status: false,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
    }),
    labelTitleErrorMessage() {
      const errorMessage = getLabelTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const accountChats = await this.$store.dispatch(
          'chatbotFunction/getChatbots'
        );

        this.chatbots = accountChats;
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
      }
    },

    onClose() {
      this.$emit('close');
    },
    async addFunction() {
      try {
        await this.$store.dispatch('chatbotFunction/create', {
          name: this.name,
          code_function: JSON.parse(this.code_function),
          status: this.status,
          chatbot_id: this.chatbot,
        });
        useAlert(
          this.$t('CHATBOT_SETTINGS.FUNCTIONS.EDIT.API.SUCCESS_MESSAGE')
        );
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message ||
          this.$t('CHATBOT_SETTINGS.FUNCTIONS.EDIT.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('CHATBOT_SETTINGS.FUNCTIONS.TITLE')"
      :header-content="$t('CHATBOT_SETTINGS.FUNCTIONS.DESCRIPTION')"
    />
    <form class="flex flex-wrap mx-0" @submit.prevent="addFunction">
      <div class="w-full mb-5">
        <label>
          {{ $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.STATUS') }}
          <woot-switch v-model="status" />
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.chatbot.$error }">
          {{ $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.CHATBOT.LABEL') }}
          <select v-model="chatbot">
            <option v-for="chat in chatbots" :key="chat.id" :value="chat.id">
              {{ chat.name }}
            </option>
          </select>
          <span v-if="v$.chatbot.$error" class="message">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
          </span>
        </label>
      </div>

      <woot-input
        v-model.trim="name"
        :class="{ error: v$.name.$error }"
        class="w-full"
        :label="$t('CHATBOT_SETTINGS.FUNCTIONS.FORM.NAME.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.NAME.PLACEHOLDER')"
        @input="v$.name.$touch"
      />
      <div class="w-full">
        <label>
          {{ $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.CODE_FUNCTION.LABEL') }}
        </label>
      </div>

      <textarea
        v-model.trim="code_function"
        :class="{ error: v$.code_function.$error }"
        class="w-full resize-none"
        :label="$t('CHATBOT_SETTINGS.FUNCTIONS.FORM.CODE_FUNCTION.LABEL')"
        :placeholder="
          $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.CODE_FUNCTION.PLACEHOLDER')
        "
        @input="v$.code_function.$touch"
      />

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <woot-button
          :is-disabled="v$.code_function.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
          data-testid="label-submit"
        >
          {{ $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.CREATE') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
// Label API supports only lowercase letters
.label-name--input {
  ::v-deep {
    input {
      @apply lowercase;
    }
  }
}

textarea {
  height: 400px;
}
</style>
