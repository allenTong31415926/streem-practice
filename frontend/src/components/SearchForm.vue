<template>
  <div class="form-container">
    <h1>Search and Visualize Data</h1>
    <form @submit.prevent="fetchData" class="search-form">
      <div class="form-group">
        <label for="query">Query:</label>
        <input type="text" id="query" v-model="form.query" required />
      </div>
      <div class="form-group">
        <label for="after">After:</label>
        <input type="date" id="after" v-model="form.after" required />
      </div>
      <div class="form-group">
        <label for="before">Before:</label>
        <input type="date" id="before" v-model="form.before" required />
      </div>
      <div class="form-group">
        <label for="interval">Interval:</label>
        <input
          type="text"
          id="interval"
          v-model="form.interval"
          required
          @input="validateInterval"
          ref="intervalInput"
        />
      </div>
      <button type="submit" class="submit-btn">Search</button>
    </form>

    <div v-if="error" class="error">
      <p>Error: {{ error }}</p>
    </div>

    <!-- Conditionally render BarChart -->
    <div v-if="chartData && chartData.labels.length">
      <BarChart :chart-data="chartData" />
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";
import axios from "@/plugins/axios";
import BarChart from "@/components/BarChart.vue";

interface ChartData {
  labels: string[];
  datasets: { label: string; data: number[] }[];
}

export default defineComponent({
  name: "SearchForm",
  components: {
    BarChart,
  },
  data() {
    // Get today's date and a date one month ago
    const today = new Date().toISOString().split("T")[0]; // Format: YYYY-MM-DD
    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1); // Subtract 1 month
    const formattedOneMonthAgo = oneMonthAgo.toISOString().split("T")[0];

    return {
      form: {
        query: "",
        after: formattedOneMonthAgo, // Default to one month ago
        before: today, // Default to today's date
        interval: "1d",
      },
      chartData: {
        labels: [],
        datasets: [
          {
            label: "No data",
            data: [],
            backgroundColor: "rgba(200, 200, 200, 0.5)", // Default gray color
          },
        ],
      } as unknown as ChartData,
      error: null as string | null,
      intervalErrorMessage:
        "Enter a positive number followed by 'd' (e.g., 1d).",
    };
  },
  computed: {
    isIntervalValid(): boolean {
      // Regex to validate interval format (positive number followed by 'd')
      const intervalRegex = /^[1-9][0-9]*d$/;
      return intervalRegex.test(this.form.interval);
    },
  },
  methods: {
    validateInterval() {
      const intervalInput = this.$refs.intervalInput as HTMLInputElement;
      if (!this.isIntervalValid) {
        intervalInput.setCustomValidity(this.intervalErrorMessage);
      } else {
        intervalInput.setCustomValidity(""); // Clear the custom error
      }
    },
    async fetchData() {
      try {
        this.error = null;
        const response = await axios.get("/results", { params: this.form });
        this.chartData = this.transformResponse(response.data);
      } catch (err: any) {
        this.error =
          err.response?.data?.error || "An unexpected error occurred.";
      }
    },
    transformResponse(data: any): ChartData {
      const labels: string[] = [];
      const datasets: {
        label: string;
        data: number[];
        backgroundColor: string;
      }[] = [];

      // Define colors for each medium type
      const colors: { [key: string]: string } = {
        Social: "rgba(255, 99, 132, 0.6)", // Pink
        Print: "rgba(128, 0, 128, 0.6)", // Purple
        Online: "rgba(255, 0, 0, 0.6)", // Red
        TV: "rgba(0, 0, 255, 0.6)", // Blue
        Radio: "rgba(0, 255, 0, 0.6)", // Green
      };

      const order = ["Radio", "TV", "Online", "Print", "Social"];

      data.aggregations.first_agg.buckets.forEach((bucket: any) => {
        labels.push(bucket.key_as_string); // Add dates to labels
        bucket.second_agg.buckets.forEach((subBucket: any) => {
          let dataset = datasets.find((d) => d.label === subBucket.key);
          if (!dataset) {
            dataset = {
              label: subBucket.key,
              data: [],
              backgroundColor:
                colors[subBucket.key] || "rgba(200, 200, 200, 0.6)", // Default to gray if no color
            };
            datasets.push(dataset);
          }
          dataset.data.push(subBucket.doc_count); // Add the count to the dataset
        });
      });

      // Ensure all datasets have the same number of data points
      datasets.forEach((dataset) => {
        while (dataset.data.length < labels.length) {
          dataset.data.push(0); // Add 0 for missing data
        }
      });

      // Reorder datasets based on the desired order
      const sortedDatasets = order
        .map((key) => datasets.find((dataset) => dataset.label === key))
        .filter((dataset) => dataset !== undefined) as {
        label: string;
        data: number[];
        backgroundColor: string;
      }[];

      return {
        labels: labels,
        datasets: sortedDatasets,
      };
    },
  },
});
</script>

<style scoped>
.form-container {
  max-width: 600px;
  margin: auto;
  font-family: Arial, sans-serif;
  text-align: center;
}

.search-form {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 1rem;
  align-items: center;
  justify-items: start;
  margin-top: 20px;
}

.form-group {
  display: contents;
}

label {
  text-align: right;
  font-weight: bold;
  padding-right: 10px;
}

input {
  width: 100%;
  padding: 8px;
  font-size: 16px;
}

.submit-btn {
  grid-column: span 2;
  padding: 10px 20px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
}

.submit-btn:hover {
  background-color: #0056b3;
}

.error {
  color: red;
  margin-top: 20px;
}

h3 {
  margin-top: 40px;
}
</style>
