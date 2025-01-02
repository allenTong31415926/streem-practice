<template>
  <div class="chart-container">
    <Bar
      v-if="processedChartData"
      :data="processedChartData"
      :options="chartOptions"
      :height="1200"
      :width="1800"
    />
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType } from "vue";
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  Chart,
} from "chart.js";
import { Bar } from "vue-chartjs";

// Register Chart.js components
ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
);

interface ChartData {
  labels: string[];
  datasets: { label: string; data: number[]; backgroundColor: string }[];
}

export default defineComponent({
  name: "BarChart",
  components: {
    Bar,
  },
  props: {
    chartData: {
      type: Object as PropType<ChartData>,
      required: true,
    },
    chartOptions: {
      type: Object,
      default: () => ({
        responsive: true,
        plugins: {
          legend: {
            position: "right",
            labels: {
              usePointStyle: true, // Use round dots in the legend
              pointStyle: "circle", // Make the dots circular
              boxWidth: 6, // Set the size of the round dot
              boxHeight: 6, // Ensure height matches width for perfect circle
              padding: 10, // Add spacing between legend items
              font: {
                size: 14, // Font size for legend labels
              },
              generateLabels: function (chart: Chart) {
                // Reverse the order of legend items
                const originalLabels =
                  ChartJS.defaults.plugins.legend.labels.generateLabels(chart);
                return originalLabels.reverse();
              },
            },
          },
          title: {
            display: true,
            text: "Count of Records by Medium",
          },
        },
        scales: {
          x: {
            stacked: true,
            title: {
              display: true,
              text: "Timestamp per day",
            },
            ticks: {
              maxRotation: 45, // Rotate x-axis labels
              minRotation: 45,
            },
          },
          y: {
            stacked: true,
            title: {
              display: true,
              text: "Count of records",
            },
            beginAtZero: true,
          },
        },
      }),
    },
  },
  data() {
    return {
      processedChartData: null as ChartData | null,
    };
  },
  watch: {
    chartData: {
      immediate: true,
      deep: true,
      handler(newData: ChartData) {
        if (newData?.labels && newData?.datasets) {
          this.processedChartData = {
            labels: [...newData.labels],
            datasets: newData.datasets.map((dataset) => ({
              ...dataset,
              data: [...dataset.data],
            })),
          };
        } else {
          this.processedChartData = {
            labels: [],
            datasets: [
              {
                label: "No data",
                data: [],
                backgroundColor: "rgba(200, 200, 200, 0.5)",
              },
            ],
          };
        }
      },
    },
  },
});
</script>

<style scoped>
.chart-container {
  width: 100%;
  max-width: 1800px;
  margin: auto;
}
</style>
