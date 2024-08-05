<template>
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <form v-if="!uiFlags.isFetchingItem" @submit.prevent="updateChatbot">
      <div
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800"
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
          <label :class="{ error: $v.promts.$error }">
            {{ $t('CHATBOT_SETTINGS.FORM_PROMPT_LABEL') }}
            <textarea
              v-model="promts"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_PROMPT_PLACEHOLDER')"
              rows="10"
              style="height: 250px"
              @blur="$v.promts.$touch"
            />
            <span v-if="$v.promts.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.email_business.$error }">
            Email del negocio
            <input
              v-model="email_business"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_EMAIL_PLACEHOLDER')"
              @blur="$v.email_business.$touch"
            />
            <span v-if="$v.email_business.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.email_notify.$error }">
            Email para recibir notificaciones
            <input
              v-model="email_notify"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_EMAIL_PLACEHOLDER')"
              @blur="$v.email_notify.$touch"
            />
            <span v-if="$v.email_notify.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <div>
            <label>{{ $t('CHATBOT_SETTINGS.FORM_QR_PLACEHOLDER') }}</label>
            <img
              src="https://upload.wikimedia.org/wikipedia/commons/d/d7/Commons_QR_code.png"
            />
          </div>

          <div
            class="flex items-center justify-between w-full gap-2 p-4 border border-solid border-ash-200 rounded-xl mt-5"
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

<script>
import { required } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import accountMixin from '../../../../mixins/account';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import semver from 'semver';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  mixins: [accountMixin, alertMixin, configMixin, uiSettingsMixin],
  data() {
    return {
      locale: 'es',
      id: '',
      promts: '',
      qr: '',
      email_business: '',
      email_notify: '',
      status: '',
    };
  },
  validations: {
    promts: {
      required,
    },
    email_business: {
      required,
    },
    email_notify: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
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
        const { id, status, promts, qr, email_business, email_notify } =
          await this.$store.dispatch('chatbot/get');

        this.id = id;
        this.status = status;
        this.promts = promts;
        this.qr = qr;
        this.email_business = email_business;
        this.email_notify = email_notify;
      } catch (error) {
        this.showAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
      }
    },

    async updateChatbot() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        await this.$store.dispatch('chatbot/update', {
          id: this.id,
          status: this.status,
          promts: this.promts,
          qr: this.qr,
          email_business: this.email_business,
          email_notify: this.email_notify,
        });
        this.$root.$i18n.locale = this.locale;
        // this.getAccount(this.id).locale = this.locale;
        // this.updateDirectionView(this.locale);
        this.showAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
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
