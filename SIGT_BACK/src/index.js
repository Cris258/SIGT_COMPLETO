import app, { initSeeders } from "./app/app.js";
import dotenv from "dotenv";
dotenv.config();
import {modelsApp} from "./config/models.app.js";

dotenv.config({path:'../.env'});
modelsApp(true);

setTimeout(async () => {
    await initSeeders();
}, 2000);

const port = process.env.SERVER_PORT || 3001;

app.listen(port, () => {
    console.log(`Connected Server ....${ port }`);
});