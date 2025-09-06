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


window.testPickImages = async () => {

    try {
        
        const result = await Camera.pickImages({ 
            limit: 5,
            quality: 90
        });
    
        const container = document.getElementById("container");
    
        if (result.photos && result.photos.length > 0) {
            const p = document.createElement("p");
            p.innerText = JSON.stringify(result.photos);
            container.appendChild(p);
    
            result.photos.forEach(function (imgSrc) {
                const img = document.createElement("img");
                img.src = imgSrc.webPath;
                img.style.width = "200px";
                img.style.margin = "10px";
                img.style.borderRadius = "8px";
                container.appendChild(img);
            });
        }
    } catch (error) {
        const container = document.getElementById('container');
        const errorContent = document.createElement("p");
        errorContent.innerText = `${ERROR} ${errorContent?.message} ${errorContent?.code}`
        container.appendChild(errorContent);
    }
    
}