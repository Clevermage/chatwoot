<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getLabelTitleErrorMessage } from './validations';
import { useVuelidate } from '@vuelidate/core';

export default {
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      chatbot: '',
      chatbots: [],
      code_function: [],
      jsonString: '',
      status: '',
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('CHATBOT_SETTINGS.FUNCTIONS.EDIT.TITLE')} - ${
        this.selectedResponse.name
      }`;
    },
    labelTitleErrorMessage() {
      const errorMessage = getLabelTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
  },
  watch: {
    selectedResponse: {
      handler() {
        this.setFormValues();
      },
      deep: true,
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async setFormValues() {
      const accountChats = await this.$store.dispatch(
        'chatbotFunction/getChatbots'
      );

      this.chatbots = accountChats;

      // Convertir el JSON a string legible para mostrar en el textarea
      this.name = this.selectedResponse.name;
      this.code_function = this.selectedResponse.code_function;
      this.chatbot = this.selectedResponse.chatbot_id;
      this.status = this.selectedResponse.status;
      this.jsonString = JSON.stringify(this.code_function, null, 2); // Formateado con espacios para legibilidad
    },
    editFunction() {
      // Intentar parsear el JSON antes de enviarlo al backend
      try {
        // this.code_function = JSON.parse(this.jsonString);
      } catch (e) {
        useAlert(this.$t('CHATBOT_SETTINGS.FUNCTIONS.EDIT.API.ERROR_MESSAGE'));
        return;
      }

      this.$store
        .dispatch('chatbotFunction/update', {
          name: this.name,
          id: this.selectedResponse.id,
          code_function: JSON.parse(this.jsonString),
          status: this.status,
          chatbot_id: this.chatbot,
        })
        .then(() => {
          useAlert(
            this.$t('CHATBOT_SETTINGS.FUNCTIONS.EDIT.API.SUCCESS_MESSAGE')
          );
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          useAlert(
            this.$t('CHATBOT_SETTINGS.FUNCTIONS.EDIT.API.ERROR_MESSAGE')
          );
        });
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto w-full">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-wrap w-full" @submit.prevent="editFunction">
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
        v-model.trim="jsonString"
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
          :is-disabled="v$.code_function.$invalid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        >
          {{ $t('CHATBOT_SETTINGS.FUNCTIONS.FORM.EDIT') }}
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
