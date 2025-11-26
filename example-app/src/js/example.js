import { MultiCamera } from 'capacitor-multi-camera';

window.testCheckPermissions = async  () => {
    const result = await MultiCamera.checkPermissions();
    const container = document.getElementById('container');
    const persmissions = document.createElement("p");
    persmissions.innerText = JSON.stringify(result);
    container.appendChild(persmissions);
}

window.testRequestPermissions = () => {
    MultiCamera.requestPermissions();
}


window.testPickImages = async () => {

    try {
        
        const result = await MultiCamera.pickImages({ 
            limit: 15,
            quality: 60
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


window.testCapture = async () => {

    try {
        const result = await MultiCamera.capture({ 
            resultType: "uri",
            saveToGallery: false,
            quality: 0.6,
            limit: 5
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