CREATE TABLE [Wildberries].[ProdArticleNomenclatureForWB]
(
	pan_id      INT CONSTRAINT [FK_ProdArticleNomenclatureForWB_pan_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclature(pan_id) NOT NULL,
	pa_id       INT CONSTRAINT [FK_ProdArticleNomenclatureForWB_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	dt			DATETIME2(0) NOT NULL,
	nm_id       INT NULL,
	wb_uid		BINARY(16) NULL,
	CONSTRAINT [PK_ProdArticleNomenclatureForWB] PRIMARY KEY CLUSTERED(pan_id)
)
