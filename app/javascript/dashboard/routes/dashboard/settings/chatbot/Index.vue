<script>
import axios from 'axios';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import semver from 'semver';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  setup() {
    const { updateUISettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const v$ = useVuelidate();

    return { updateUISettings, v$, enabledLanguages };
  },
  data() {
    return {
      showDeleteConfirmationPopup: false,
      imageExists: '',
      selectedResponse: {},
      loading: {},
      locale: 'es',
      id: '',
      name: '',
      instructions: '',
      qr: '',
      email_notify: '',
      status: '',
      type_chatbot_id: '',
      type_chatbot_provider_id: '',
      meta_jwt_token: '',
      meta_number_id: '',
      meta_verify_token: '',
      meta_version: '',
      status_chatbot: '',
      status_scanqr: '',
    };
  },
  validations: {
    instructions: {
      required,
    },
    name: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      uiFlags: 'accounts/getUIFlags',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    deleteMessage() {
      return ` ${this.selectedResponse.name}?`;
    },
    showAutoResolutionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.AUTO_RESOLVE_CONVERSATIONS
      );
    },
    hasAnUpdateAvailable() {
      if (!semver.valid(this.latestChatwootVersion)) {
        return false;
      }

      return semver.lt(
        this.globalConfig.appVersion,
        this.latestChatwootVersion
      );
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },

    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },

    featureCustomReplyDomainEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_domain
      );
    },

    featureCustomReplyEmailEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_email
      );
    },

    getAccountId() {
      return this.id.toString();
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const {
          id,
          status,
          name,
          instructions,
          qr,
          email_notify,
          type_chatbot_id,
          type_chatbot_provider_id,
          meta_jwt_token,
          meta_number_id,
          meta_verify_token,
          meta_version,
          status_scanqr,
        } = await this.$store.dispatch('chatbot/get');

        this.id = id;
        this.status = status;
        this.name = name;
        this.instructions = instructions;
        this.qr = qr;
        this.email_notify = email_notify;
        this.type_chatbot_id = type_chatbot_id;
        this.type_chatbot_provider_id = type_chatbot_provider_id;
        this.meta_jwt_token = meta_jwt_token;
        this.meta_number_id = meta_number_id;
        this.meta_verify_token = meta_verify_token;
        this.meta_version = meta_version;
        this.status_scanqr = status_scanqr;
        if (this.type_chatbot_provider_id === 2) {
          this.checkQRImage();
        }
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
      }
    },

    async checkQRImage() {
      try {
        const response = await axios.get(this.qr, {
          responseType: 'blob',
        });

        if (response.status === 200) {
          this.imageExists = true;
          if (this.status_scanqr) {
            this.status_chatbot = 'Activo';
          } else {
            this.status_chatbot =
              'Se requiere escanear el código QR desde la APP de WhatsApp';
          }
        } else {
          this.imageExists = false;
          this.status_chatbot = 'No Activo';
        }
      } catch (err) {
        this.imageExists = false;
        this.status_chatbot = 'No Activo';
      }
    },

    async updateChatbot() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        const payload = {
          id: this.id,
          status: this.status,
          name: this.name,
          instructions: this.instructions,
          qr: this.qr,
          email_business: this.email_business,
          email_notify: this.email_notify,
          type_chatbot_id: this.type_chatbot_id,
          meta_jwt_token: this.meta_jwt_token,
          meta_number_id: this.meta_number_id,
          meta_verify_token: this.meta_verify_token,
          meta_version: this.meta_version,
        };

        await this.$store.dispatch('chatbot/update', payload);
        this.$root.$i18n.locale = this.locale;
        // this.getAccount(this.id).locale = this.locale;
        // this.updateDirectionView(this.locale);
        this.initializeAccount();
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },

    updateDirectionView(locale) {
      const isRTLSupported = getLanguageDirection(locale);
      this.updateUISettings({
        rtl_view: isRTLSupported,
      });
    },
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <form v-if="!uiFlags.isFetchingItem" @submit.prevent="updateChatbot">
      <div
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800 flex-[50%]"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('CHATBOT_SETTINGS.FORM_GENERAL_SECTION_TITLE') }}
          </h4>
          <p>{{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE') }}</p>
        </div>
        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <div
            class="flex items-center justify-between w-full gap-2 p-4 border border-solid border-ash-200 rounded-xl mb-5"
          >
            <div class="flex flex-row items-center gap-2">
              <fluent-icon
                icon="alert"
                class="flex-shrink-0 text-ash-900"
                size="18"
              />
              <span class="text-sm text-ash-900">
                {{ $t('CHATBOT_SETTINGS.FORM_STATUS_LABEL') }}
              </span>

              <woot-switch v-model="status" />
            </div>
          </div>

          <label :class="{ error: v$.name.$error }">
            {{ $t('CHATBOT_SETTINGS.FORM_NAME_BUSINESS_LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="
                $t('CHATBOT_SETTINGS.FORM_NAME_BUSINESS_PLACEHOLDER')
              "
              @blur="v$.name.$touch"
            />
            <span v-if="v$.name.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>

          <label :class="{ error: v$.instructions.$error }">
            {{ $t('CHATBOT_SETTINGS.FORM_PROMPT_LABEL') }}
            <textarea
              v-model="instructions"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_PROMPT_PLACEHOLDER')"
              rows="10"
              class="chatbot-textarea"
              @blur="v$.instructions.$touch"
            />
            <span v-if="v$.instructions.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>

          <label>
            {{ $t('CHATBOT_SETTINGS.FORM_EMAIL_NOTIFY') }}
            <input
              v-model="email_notify"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_EMAIL_PLACEHOLDER')"
            />
          </label>

          <div
            v-if="type_chatbot_provider_id === 2"
            class="flex w-full color-custom p-[15px]"
          >
            <div class="w-1/2 flex items-start">
              <p class="text-sm">
                <b>{{ $t('CHATBOT_SETTINGS.STATUS_CHATBOT') }}</b>
                <span
                  :class="{
                    'text-green': imageExists,
                    'text-red': !imageExists && status_scanqr,
                    'text-yellow': !status_scanqr,
                  }"
                >
                  <b>{{ status_chatbot }}</b>
                </span>
              </p>
            </div>

            <div
              v-if="imageExists"
              class="w-1/2 flex items-center justify-center"
            >
              <img :src="qr" class="chatbot-qr" />
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="type_chatbot_provider_id === 1"
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800 flex-[50%]"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('CHATBOT_SETTINGS.FORM_META_SECTION_TITLE') }}
          </h4>
        </div>

        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <label>
            {{ $t('CHATBOT_SETTINGS.FORM_META_JWT_TOKEN') }}
            <input
              v-model="meta_jwt_token"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_META_JWT_TOKEN')"
            />
          </label>
          <label>
            {{ $t('CHATBOT_SETTINGS.FORM_META_NUMBER_ID') }}
            <input
              v-model="meta_number_id"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_META_NUMBER_ID')"
            />
          </label>
          <label>
            {{ $t('CHATBOT_SETTINGS.FORM_META_VERIFY_TOKEN') }}
            <input
              v-model="meta_verify_token"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_META_VERIFY_TOKEN')"
            />
          </label>
          <label>
            {{ $t('CHATBOT_SETTINGS.FORM_META_VERSION') }}
            <input
              v-model="meta_version"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_META_VERSION')"
            />
          </label>
        </div>
      </div>

      <woot-submit-button
        class="button nice success button--fixed-top"
        :button-text="$t('GENERAL_SETTINGS.SUBMIT')"
        :loading="isUpdating"
      />
    </form>

    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>

<style lang="scss">
.chatbot-qr {
  height: 200px;
}

.chatbot-textarea {
  height: 250px;
}

.text-green {
  color: green;
}

.text-red {
  color: red;
}

.text-black {
  color: black;
}

.text-yellow {
  color: cornflowerblue;
}

.color-custom {
  background-color: #f2f3f5;
}
</style>
