<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { message } from "ant-design-vue";
import { DashboardOutlined, ReloadOutlined } from "@ant-design/icons-vue";
import { getStats } from "@/api/admin";
import { isSessionExpiredError } from "@/lib/authError";
import type { AdminStats } from "@/types";

const loading = ref(false);
const stats = ref<AdminStats | null>(null);

const overviewStats = computed(() => {
  if (!stats.value) return [];
  return [
    {
      key: "total_tasks",
      label: "所有时间总任务数",
      value: stats.value.total_tasks,
      desc: "累计发起的全部任务数量（含提示词反推）",
      color: "#1890ff",
    },
    {
      key: "total_credit_cost",
      label: "所有时间总积分消耗",
      value: stats.value.total_credit_cost,
      desc: "累计任务实际扣减的积分总量（含提示词反推）",
      color: "#722ed1",
    },
    {
      key: "active_users",
      label: "近 7 天活跃用户",
      value: stats.value.active_users,
      desc: "按最近 7 天内发起任务或提示词反推计算",
      color: "#13c2c2",
    },
    {
      key: "total_users",
      label: "总用户数",
      value: stats.value.total_users,
      desc: "当前系统内非超级管理员用户",
      color: "#fa8c16",
    },
  ];
});

async function load() {
  loading.value = true;
  try {
    stats.value = await getStats();
  } catch (err: any) {
    if (isSessionExpiredError(err)) return;
    message.error("获取概览统计失败");
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  void load();
});
</script>

<template>
  <div class="warm-page motion-page-enter">
    <div class="warm-page-header motion-fade-up" style="--motion-delay: 40ms">
      <div class="warm-page-heading">
        <div class="warm-page-icon">
          <DashboardOutlined />
        </div>
        <div>
          <div class="warm-page-title">固定概览</div>
          <div class="warm-page-desc">查看全量累计口径的任务、积分与用户数据，不随筛选条件变化。</div>
        </div>
      </div>
      <a-button class="warm-secondary-btn" :loading="loading" @click="load">
        <template #icon><ReloadOutlined /></template>
        刷新
      </a-button>
    </div>

    <section class="dashboard-section">
      <div class="section-title-row">
        <h3 class="section-title">固定概览</h3>
        <span class="section-tip">这一组为固定口径统计，不随当前筛选条件变化。</span>
      </div>
      <a-spin :spinning="loading">
        <div class="overview-grid">
          <div
            v-for="(item, index) in overviewStats"
            :key="item.key"
            class="overview-card warm-card motion-card-lift motion-fade-up"
            :style="{ '--motion-delay': `${160 + Math.min(index, 5) * 40}ms` }"
          >
            <div class="overview-card-head">
              <span class="overview-card-label">{{ item.label }}</span>
              <span class="overview-card-dot" :style="{ background: item.color }" />
            </div>
            <div class="overview-card-value" :style="{ color: item.color }">{{ item.value }}</div>
            <div class="overview-card-desc">{{ item.desc }}</div>
          </div>
        </div>
      </a-spin>
    </section>
  </div>
</template>

<style scoped lang="scss">
.dashboard-section {
  padding-top: 2px;
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
}

.overview-card {
  min-height: 116px;
  padding: 16px 18px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  justify-content: space-between;
}

.overview-card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.overview-card-label {
  color: #8c7458;
  font-size: 13px;
  font-weight: 700;
}

.overview-card-dot {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  box-shadow: 0 0 0 4px rgba(255, 193, 90, 0.14);
}

.overview-card-value {
  font-size: 30px;
  line-height: 1.1;
  font-weight: 700;
  letter-spacing: -0.02em;
}

.overview-card-desc {
  color: #9a805b;
  font-size: 12px;
  line-height: 1.5;
}

.section-title-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
  flex-wrap: wrap;
  padding: 0 2px;
}

.section-title {
  font-size: 16px;
  font-weight: 700;
  color: #5d4526;
  margin: 0;
  position: relative;
  padding-left: 14px;

  &::before {
    content: "";
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 6px;
    height: 18px;
    border-radius: 999px;
    background: linear-gradient(180deg, #ffc45b, #ffab25);
    box-shadow: 0 6px 12px rgba(255, 169, 37, 0.24);
  }
}

.section-tip {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
  font-size: 13px;
  color: #8c7458;
}
</style>
