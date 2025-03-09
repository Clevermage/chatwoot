<!-- eslint-disable vue/v-slot-style -->
<script>
import { useAgentsList } from 'dashboard/composables/useAgentsList';

export default {
  setup() {
    const { agentsList } = useAgentsList();
    return {
      agentsList,
    };
  },
  data() {
    return {
      text: 'hola',
    };
  },
  computed: {
    hasAnAssignedTeam() {
      return !!this.currentChat?.meta?.team;
    },
    teamsList() {
      if (this.hasAnAssignedTeam) {
        return [
          { id: 0, name: this.$t('TEAMS_SETTINGS.LIST.NONE') },
          ...this.teams,
        ];
      }
      return this.teams;
    },
  },
};
</script>
