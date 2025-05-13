// 页面加载完成后默认选中“生成代码签名”
document.addEventListener('DOMContentLoaded', function () {
    const defaultButton = document.querySelector('.tool-button[data-tool="generateCodeSignature"]');
    if (defaultButton) {
        defaultButton.classList.add('active');
        toggleFormFields('generateCodeSignature');
    }
});

// 更新工具选择器事件监听
document.querySelectorAll('.tool-button').forEach(button => {
    button.addEventListener('click', function () {
        // 移除所有 active 类
        document.querySelectorAll('.tool-button').forEach(btn => btn.classList.remove('active'));

        // 添加 active 到当前点击的按钮
        this.classList.add('active');

        // 触发表单字段切换
        const tool = this.getAttribute('data-tool');
        toggleFormFields(tool);
    });
});

// 修改 toggleFormFields 函数以接受参数
function toggleFormFields(tool) {
    document.querySelectorAll('.form-group').forEach(el => {
        el.classList.remove('visible');
    });

    if (tool && toolConfig[tool]) {
        toolConfig[tool].forEach(id => {
            document.getElementById(id).classList.add('visible');
        });
    }
}

// 工具字段可见性配置
const toolConfig = {
    generateCodeSignature: ['signatureExplain', 'codeGroup', 'signatureFields'],
    refactorVariable: ['refactorExplain', 'codeGroup', 'refactorFields'],
    generateDocument: ['documentExplain', 'codeGroup', 'documentFields'],
    foldConstant: ['foldExplain', 'codeGroup', 'foldConstantFields']
};
/*
// 切换可见表单项
function toggleFormFields() {
    // 隐藏所有表单项
    document.querySelectorAll('.form-group').forEach(el => {
        el.classList.remove('visible');
    });

    // 显示当前工具需要的表单项
    const tool = document.getElementById('toolSelector').value;
    if (tool && toolConfig[tool]) {
        toolConfig[tool].forEach(id => {
            document.getElementById(id).classList.add('visible');
        });
    }
}
*/
// 提交表单
async function submitForm() {
    const tool = document.getElementById('toolSelector').value;
    const code = document.getElementById('code').value;
    const resultElement = document.getElementById('result');

    // 构建请求数据
    let requestData = { tool, code };

    // 收集工具特定参数
    switch (tool) {
        case 'refactorVariable':
            requestData.path = document.getElementById('path').value;
            requestData.oldName = document.getElementById('oldName').value;
            requestData.newName = document.getElementById('newName').value;
            break;
        case 'generateDocument':
            requestData.path = document.getElementById('path').value;
            break;
    }

    try {
        const response = await fetch('http://127.0.0.1:8080/process', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(requestData).toString()
        });

        if (response.headers.get('content-type')?.includes('application/json')) {
            const data = await response.json();
            if (data.status === 'success') {
                resultElement.textContent = data.result;
                resultElement.style.color = '#333';
            } else {
                resultElement.textContent = `错误：${data.message}`;
                resultElement.style.color = 'red';
            }
        } else {
            const text = await response.text();
            resultElement.textContent = text;
            resultElement.style.color = 'red';
        }
    } catch (error) {
        resultElement.textContent = `请求失败：${error.message}`;
        resultElement.style.color = 'red';
    }
}