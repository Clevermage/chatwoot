<script>
import WootReports from './components/WootReports.vue';

export default {
  components: {
    WootReports,
  },
};
</script>

<template>
  <WootReports
    key="agent-reports"
    type="agent"
    getter-key="agents/getAgents"
    action-key="agents/get"
    :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
  />
</template>
