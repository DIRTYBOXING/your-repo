import { io } from "socket.io-client";

const SERVER = process.env.REACT_APP_SERVER || "http://localhost:3001";
export const socket = io(SERVER, { autoConnect: false });
