import { Camera } from 'capacitor-multi-camera';

window.testCheckPermissions = async  () => {
    const result = await Camera.checkPermissions();
    const container = document.getElementById('container');
    const persmissions = document.createElement("p");
    persmissions.innerText = JSON.stringify(result);
    container.appendChild(persmissions);
}

window.testRequestPermissions = () => {
    Camera.requestPermissions();
}