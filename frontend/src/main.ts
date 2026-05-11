import { createApp } from "vue";
import { createPinia } from "pinia";
import Antd, { message } from "ant-design-vue";
import "ant-design-vue/dist/reset.css";
import App from "./App.vue";
import { initializeAppTheme } from "./lib/theme";
import router from "./router";
import "./styles/global.scss";

initializeAppTheme();

message.config({
  duration: 2.4,
  maxCount: 3,
});

const app = createApp(App);
app.use(createPinia());
app.use(router);
app.use(Antd);
app.mount("#app");
